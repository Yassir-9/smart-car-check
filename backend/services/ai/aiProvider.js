const SUPPORTED_PROVIDERS = new Set(['gemini', 'anthropic']);

function selectedProviderName() {
  const name = (process.env.AI_PROVIDER || 'gemini').trim().toLowerCase();
  if (!SUPPORTED_PROVIDERS.has(name)) {
    throw new Error(`Unsupported AI_PROVIDER: ${name}`);
  }
  return name;
}

function getAiProvider() {
  const name = selectedProviderName();
  if (name === 'anthropic') return require('./anthropicProvider');
  return require('./geminiProvider');
}

module.exports = { getAiProvider, selectedProviderName, SUPPORTED_PROVIDERS };
