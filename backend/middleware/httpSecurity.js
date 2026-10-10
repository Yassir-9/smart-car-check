const defaultOrigins = [
  'https://yassir-9.github.io',
  'http://localhost',
  'http://localhost:3000',
  'http://localhost:5000',
  'http://localhost:8000',
  'http://localhost:8080',
  'http://127.0.0.1:3000',
  'http://127.0.0.1:5000',
  'http://127.0.0.1:8000',
  'http://127.0.0.1:8080',
];

function isLoopbackOrigin(origin) {
  try {
    const url = new URL(origin);
    return url.protocol === 'http:' &&
      (url.hostname === 'localhost' || url.hostname === '127.0.0.1');
  } catch (_) {
    return false;
  }
}

function createCorsOptions(configuredValue = process.env.ALLOWED_ORIGINS || '') {
  const configuredOrigins = configuredValue
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
  const allowedOrigins = new Set([...defaultOrigins, ...configuredOrigins]);
  return {
    allowedOrigins,
    options: {
      origin(origin, callback) {
        // Native/mobile clients and server-to-server requests do not send Origin.
        if (!origin || allowedOrigins.has(origin) || isLoopbackOrigin(origin)) {
          return callback(null, true);
        }
        const error = new Error('Origin is not allowed by CORS');
        error.statusCode = 403;
        return callback(error);
      },
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'x-admin-secret', 'x-app-locale'],
    },
  };
}

const helmetOptions = {
  crossOriginResourcePolicy: { policy: 'cross-origin' },
};

module.exports = { createCorsOptions, defaultOrigins, helmetOptions, isLoopbackOrigin };
