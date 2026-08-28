const Anthropic = require('@anthropic-ai/sdk');

function client() {
  if (!process.env.ANTHROPIC_API_KEY) throw new Error('ANTHROPIC_API_KEY is not configured');
  return new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
}

async function generate({ system, prompt, image, maxOutputTokens = 900, useWebSearch = false }) {
  const content = [];
  if (image?.data) {
    content.push({
      type: 'image',
      source: { type: 'base64', media_type: image.media_type || 'image/jpeg', data: image.data },
    });
  }
  content.push({ type: 'text', text: prompt });
  const response = await client().messages.create({
    model: process.env.AI_MODEL || 'claude-sonnet-4-6',
    max_tokens: maxOutputTokens,
    system,
    messages: [{ role: 'user', content }],
    ...(useWebSearch ? { tools: [{ type: 'web_search_20250305', name: 'web_search' }] } : {}),
  });
  const text = response.content
    .filter((block) => block.type === 'text')
    .map((block) => block.text)
    .join('\n')
    .trim();
  if (!text) throw new Error('Anthropic returned an empty response');
  return text;
}

module.exports = {
  name: 'anthropic',
  generateJson: generate,
  generateText: generate,
};
