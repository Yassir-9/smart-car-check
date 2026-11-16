// Static checks on ../firestore.rules. These do NOT execute the rules (that
// needs the Firestore emulator + Java); they guard the structure so a client
// can never be granted write access to Backend-managed user data.
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const rules = fs.readFileSync(path.join(__dirname, '..', '..', 'firestore.rules'), 'utf8');
const usersBlock = rules.slice(rules.indexOf('match /users/{uid}'), rules.indexOf('// Public reads'));

const CLIENT_COLLECTIONS = [
  'cars', 'vehicle_issues', 'repairs', 'repair_verifications',
  'maintenance_records', 'maintenance_reminders',
];
const BACKEND_ONLY = ['subscription', 'usage', 'history', 'diagnosis_cache', 'repair_reviews'];

test('no wildcard write under users/{uid}', () => {
  const wildcard = usersBlock.match(/match \/\{document=\*\*\}\s*\{[^}]*\}/);
  assert.ok(wildcard, 'owner read wildcard should exist');
  assert.doesNotMatch(wildcard[0], /allow\s+(write|create|update|delete)/);
});

test('client write is an allowlist of the collections the app uses', () => {
  const allowlist = usersBlock.match(/clientCollection in \[([^\]]*)\]/);
  assert.ok(allowlist, 'allowlist should exist');
  const names = [...allowlist[1].matchAll(/'([a-z_]+)'/g)].map((m) => m[1]).sort();
  assert.deepEqual(names, [...CLIENT_COLLECTIONS].sort());
});

test('Backend-managed collections are never in the client write allowlist', () => {
  const allowlist = usersBlock.match(/clientCollection in \[([^\]]*)\]/)[1];
  for (const name of BACKEND_ONLY) assert.ok(!allowlist.includes(`'${name}'`), name);
});

test('deleted/pending accounts remain blocked for client writes', () => {
  assert.match(usersBlock, /allow write: if accountCanWrite\(uid\)/);
});

test('everything outside users/{uid} stays server-only', () => {
  assert.match(rules, /match \/\{document=\*\*\}\s*\{\s*allow read, write: if false;/);
});
