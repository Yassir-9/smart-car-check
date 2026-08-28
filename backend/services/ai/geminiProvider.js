const GEMINI_API_BASE = 'https://generativelanguage.googleapis.com/v1beta';
const DEFAULT_MODEL = 'gemini-3.7-flash';
const REQUEST_TIMEOUT_MS = 30000;
const logger = require('../../utils/logger');

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
  const model = modelId();
  const endpoint = endpointFor(model);
  const parts = [];
  if (image?.data) {
    parts.push({ inlineData: { mimeType: image.media_type || 'image/jpeg', data: image.data } });
  }
  parts.push({ text: prompt });

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
  let response;
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
  } catch (cause) {
    const timedOut = cause?.name === 'AbortError';
    logger.warn('AI provider request failed', {
      provider: 'gemini',
      model,
      status: timedOut ? 'timeout' : 'network_error',
      endpointPath: new URL(endpoint).pathname,
    });
    const error = new Error(timedOut ? 'Gemini request timed out' : 'Gemini network request failed');
    error.provider = 'gemini';
    error.model = model;
    error.endpointPath = new URL(endpoint).pathname;
    throw error;
  } finally {
    clearTimeout(timeout);
  }
  const data = await response.json().catch(() => null);
  if (!response.ok) {
    const googleMessage = safeGoogleMessage(data);
    logger.warn('AI provider request failed', {
      provider: 'gemini',
      model,
      status: response.status,
      endpointPath: new URL(endpoint).pathname,
      ...(googleMessage ? { message: googleMessage } : {}),
    });
    const error = new Error(`Gemini request failed with status ${response.status}`);
    error.status = response.status;
    error.provider = 'gemini';
    error.model = model;
    error.endpointPath = new URL(endpoint).pathname;
    throw error;
  }
  const text = extractText(data);
  if (!text) throw new Error('Gemini returned an empty response');
  return text;
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
  endpointFor,
};
