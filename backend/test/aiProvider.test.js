const test = require('node:test');
const assert = require('node:assert/strict');
const { selectedProviderName, getAiProvider } = require('../services/ai/aiProvider');

test('Gemini is the default provider', () => {
  const previous = process.env.AI_PROVIDER;
  delete process.env.AI_PROVIDER;
  assert.equal(selectedProviderName(), 'gemini');
  if (previous !== undefined) process.env.AI_PROVIDER = previous;
});

test('unsupported providers fail clearly', () => {
  const previous = process.env.AI_PROVIDER;
  process.env.AI_PROVIDER = 'unknown-provider';
  assert.throws(() => selectedProviderName(), /Unsupported AI_PROVIDER/);
  if (previous === undefined) delete process.env.AI_PROVIDER;
  else process.env.AI_PROVIDER = previous;
});

test('explicit Gemini selection never resolves to Anthropic', () => {
  const previous = process.env.AI_PROVIDER;
  process.env.AI_PROVIDER = 'gemini';
  assert.equal(selectedProviderName(), 'gemini');
  assert.equal(getAiProvider().name, 'gemini');
  if (previous === undefined) delete process.env.AI_PROVIDER;
  else process.env.AI_PROVIDER = previous;
});
