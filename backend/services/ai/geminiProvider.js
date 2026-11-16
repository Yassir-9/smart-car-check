const GEMINI_API_BASE = 'https://generativelanguage.googleapis.com/v1beta';
const DEFAULT_MODEL = 'gemini-3.7-flash';
const FALLBACK_MODEL = 'gemini-3.6-flash';
const logger = require('../../utils/logger');
const TRANSIENT_STATUSES = new Set([429, 500, 502, 503, 504]);
const MAX_ATTEMPTS = 3;
// Every attempt gets its own timeout; the whole generate() call has a hard ceiling.
const DEFAULT_ATTEMPT_TIMEOUT_MS = 25000;
const DEFAULT_TOTAL_TIMEOUT_MS = 45000;
const MAX_RETRY_DELAY_MS = 8000;

function positiveInt(value, fallback) {
  const parsed = Number.parseInt(String(value ?? '').trim(), 10);
  return Number.isInteger(parsed) && parsed > 0 ? parsed : fallback;
}

const attemptTimeoutMs = () => positiveInt(process.env.GEMINI_ATTEMPT_TIMEOUT_MS, DEFAULT_ATTEMPT_TIMEOUT_MS);
const totalTimeoutMs = () => positiveInt(process.env.GEMINI_TOTAL_TIMEOUT_MS, DEFAULT_TOTAL_TIMEOUT_MS);

// Exponential backoff with jitter (base, 2x base, 4x base ...), capped. A
// Retry-After header is honoured but also capped.
function retryDelayMs(attempt, retryAfter) {
  if (retryAfter) {
    const seconds = Number(retryAfter);
    if (Number.isFinite(seconds)) return Math.min(MAX_RETRY_DELAY_MS, Math.max(0, seconds * 1000));
    const date = Date.parse(retryAfter);
    if (Number.isFinite(date)) return Math.min(MAX_RETRY_DELAY_MS, Math.max(0, date - Date.now()));
  }
  const base = Number(process.env.GEMINI_RETRY_BASE_MS || 1500);
  const jitter = Math.floor(Math.random() * Math.max(1, base * 0.25));
  return Math.min(MAX_RETRY_DELAY_MS, Math.round(base * 2 ** (attempt - 1) + jitter));
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

function timeoutError(model, endpoint) {
  const error = new Error('Gemini request timed out');
  error.code = 'AI_TIMEOUT';
  error.timedOut = true;
  error.provider = 'gemini';
  error.model = model;
  error.endpointPath = new URL(endpoint).pathname;
  return error;
}

function modelId(value = process.env.AI_MODEL || DEFAULT_MODEL) {
  const normalized = String(value).trim().replace(/^models\//i, '');
  if (!normalized || !/^[a-zA-Z0-9._-]+$/.test(normalized)) {
    throw new Error('AI_MODEL must contain a valid Gemini model ID');
  }
  return normalized;
}

function endpointFor(model) {
  return `${GEMINI_API_BASE}/models/${encodeURIComponent(model)}:generateContent`;
}

function safeGoogleMessage(data) {
  const message = data?.error?.message;
  if (typeof message !== 'string') return undefined;
  return message
    .replace(/AIza[\w-]+/g, '[REDACTED]')
    .replace(/([?&]key=)[^\s&]+/gi, '$1[REDACTED]')
    .slice(0, 500);
}

function extractText(data) {
  return (data?.candidates || [])
    .flatMap((candidate) => candidate.content?.parts || [])
    .map((part) => part.text || '')
    .join('\n')
    .trim();
}

async function generate({ system, prompt, image, maxOutputTokens = 900, json = false, useWebSearch = false, responseSchema }) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) throw new Error('GEMINI_API_KEY is not configured');
  const primaryModel = modelId();
  const parts = [];
  if (image?.data) {
    parts.push({ inlineData: { mimeType: image.media_type || 'image/jpeg', data: image.data } });
  }
  parts.push({ text: prompt });

  const startedAt = Date.now();
  const deadline = startedAt + totalTimeoutMs();
  let model = primaryModel;
  let fallbackUsed = false;
  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt += 1) {
    const endpoint = endpointFor(model);
    const remaining = deadline - Date.now();
    if (remaining <= 0) throw timeoutError(model, endpoint);

    // A fresh controller and timer per attempt, never longer than the time left.
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), Math.min(attemptTimeoutMs(), remaining));
    let response;
    let data;
    try {
      response = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
        signal: controller.signal,
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: system }] },
          contents: [{ role: 'user', parts }],
          generationConfig: {
            maxOutputTokens,
            temperature: 0.2,
            thinkingConfig: { thinkingBudget: 256 },
            ...(json ? { responseMimeType: 'application/json', ...(responseSchema ? { responseSchema } : {}) } : {}),
          },
          ...(useWebSearch ? { tools: [{ google_search: {} }] } : {}),
        }),
      });
      // The body is read under the same timer, so a stalled stream cannot hang.
      data = await response.json().catch((cause) => {
        if (cause?.name === 'AbortError') throw cause;
        return null;
      });
    } catch (cause) {
      const timedOut = cause?.name === 'AbortError';
      logger.warn('AI provider request failed', {
        provider: 'gemini',
        model,
        status: timedOut ? 'timeout' : 'network_error',
        attempt,
        endpointPath: new URL(endpoint).pathname,
      });
      if (timedOut) throw timeoutError(model, endpoint);
      const error = new Error('Gemini network request failed');
      error.provider = 'gemini';
      error.model = model;
      error.endpointPath = new URL(endpoint).pathname;
      throw error;
    } finally {
      clearTimeout(timeout);
    }

    if (!response.ok) {
      const googleMessage = safeGoogleMessage(data);
      logger.warn('AI provider request failed', {
        provider: 'gemini',
        model,
        status: response.status,
        attempt,
        endpointPath: new URL(endpoint).pathname,
        ...(googleMessage ? { message: googleMessage } : {}),
      });
      const error = new Error(`Gemini request failed with status ${response.status}`);
      error.status = response.status;
      error.provider = 'gemini';
      error.model = model;
      error.endpointPath = new URL(endpoint).pathname;
      if (TRANSIENT_STATUSES.has(response.status) && attempt < MAX_ATTEMPTS) {
        if (!fallbackUsed && model === primaryModel) {
          model = FALLBACK_MODEL;
          fallbackUsed = true;
          logger.warn('Gemini fallback model selected', { provider: 'gemini', primaryModel, fallbackModel: FALLBACK_MODEL, fallbackUsed: true, status: response.status });
          continue;
        }
        const delay = retryDelayMs(attempt, response.headers?.get?.('retry-after'));
        // Not enough time left to wait and still make a useful attempt: stop now.
        if (deadline - Date.now() <= delay) throw error;
        await sleep(delay);
        continue;
      }
      throw error;
    }
    const text = extractText(data);
    if (!text) throw new Error('Gemini returned an empty response');
    return text;
  }
}

async function healthCheck() {
  await generate({
    system: 'Respond with only OK.',
    prompt: 'Return OK',
    maxOutputTokens: 16,
  });
  return { ok: true, provider: 'gemini', model: modelId() };
}

module.exports = {
  name: 'gemini',
  generateJson: (options) => generate({ ...options, json: true }),
  generateText: (options) => generate({ ...options, json: false }),
  healthCheck,
  modelId,
  retryDelayMs,
  endpointFor,
};
