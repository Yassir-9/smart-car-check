const REDACTED_KEYS = /authorization|token|secret|password|credential|api[-_]?key|firebase|phone|mobile|contact/i;

function sanitize(value, depth = 0) {
  if (depth > 3) return '[truncated]';
  if (value instanceof Error) return { name: value.name, message: value.message };
  if (Array.isArray(value)) return value.slice(0, 20).map((item) => sanitize(item, depth + 1));
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.entries(value).map(([key, item]) => [
      key,
      REDACTED_KEYS.test(key) ? '[redacted]' : sanitize(item, depth + 1),
    ]));
  }
  if (typeof value === 'string' && value.length > 500) return `${value.slice(0, 500)}…`;
  return value;
}

function write(level, message, context) {
  const entry = {
    timestamp: new Date().toISOString(),
    level,
    message,
    ...(context ? { context: sanitize(context) } : {}),
  };
  const output = JSON.stringify(entry);
  if (level === 'error') console.error(output);
  else if (level === 'warn') console.warn(output);
  else console.log(output);
}

module.exports = {
  sanitize,
  info: (message, context) => write('info', message, context),
  warn: (message, context) => write('warn', message, context),
  error: (message, error, context) => write('error', message, { ...(context || {}), error }),
};
