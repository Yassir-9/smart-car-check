const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

test('the public APK download route and file are gone', () => {
  const root = path.join(__dirname, '..');
  assert.equal(fs.existsSync(path.join(root, 'routes', 'download.js')), false);
  assert.equal(fs.existsSync(path.join(root, 'public', 'downloads', 'app-release.apk')), false);
  const server = fs.readFileSync(path.join(root, 'server.js'), 'utf8');
  assert.doesNotMatch(server, /\/download|downloadRoutes/);
});
