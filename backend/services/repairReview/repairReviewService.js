const { buildRepairReviewPrompt, buildRepairReviewCorrectionPrompt } = require('./repairReviewPrompt');
const { REPAIR_REVIEW_SCHEMA, validateRepairReview, normalizeRepairReview, fallbackRepairReview } = require('./repairReviewSchema');

const MAX_OUTPUT_TOKENS = 1800;

function parseAndValidate(raw) {
  const parsed = JSON.parse(String(raw).replace(/```json|```/g, '').trim());
  const errors = validateRepairReview(parsed);
  if (errors.length > 0) {
    const error = new Error(`Repair review schema validation failed: ${errors.join(', ')}`);
    error.code = 'INVALID_REPAIR_REVIEW';
    throw error;
  }
  return normalizeRepairReview(parsed);
}

async function generateRepairReview({ provider, input, image }) {
  const { system, prompt } = buildRepairReviewPrompt(input);
  let raw;
  try {
    raw = await provider.generateJson({
      system, prompt, image, maxOutputTokens: MAX_OUTPUT_TOKENS,
      responseSchema: REPAIR_REVIEW_SCHEMA,
    });
  } catch (_) {
    return fallbackRepairReview();
  }
  try {
    return parseAndValidate(raw);
  } catch (firstError) {
    try {
      const corrected = await provider.generateJson({
        system,
        prompt: buildRepairReviewCorrectionPrompt(input, firstError.message),
        image: null,
        maxOutputTokens: MAX_OUTPUT_TOKENS,
        responseSchema: REPAIR_REVIEW_SCHEMA,
      });
      return parseAndValidate(corrected);
    } catch (_) {
      return fallbackRepairReview();
    }
  }
}

module.exports = { generateRepairReview, parseAndValidate, MAX_OUTPUT_TOKENS };
