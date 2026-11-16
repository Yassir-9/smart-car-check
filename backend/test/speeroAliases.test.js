const test = require('node:test');
const assert = require('node:assert/strict');

const { SPEERO_ALIASES, speeroTerm, normalizeAliasKey } = require('../config/speeroAliases');
const { buildDestination } = require('../services/partsGuide/storeRedirect');

const speero = (part, extra = {}) => buildDestination('speero', { q: part, fields: { part, ...extra } }, {});

test('known terms are replaced, ignoring case and extra spaces', () => {
  assert.equal(speeroTerm('MAF Sensor'), 'Air Flow Sensor');
  assert.equal(speeroTerm('  maf   SENSOR '), 'Air Flow Sensor');
  assert.equal(speeroTerm('Transmission Mounts'), 'كرسي قير');
});

test('terms that are not in the dictionary are returned untouched', () => {
  for (const term of ['Spark Plugs', 'Ignition Coils', 'Throttle Body', 'Engine Mounts', 'شمعات احتراق', 'MAF Sensor Connector', '']) {
    assert.equal(speeroTerm(term), term);
  }
  assert.equal(speeroTerm(undefined), undefined);
});

test('odd or hostile text never reaches the dictionary as a key and is not altered', () => {
  for (const term of ['__proto__', 'constructor', 'toString', 'hasOwnProperty', 'maf sensor; DROP TABLE', 'maf sensor<script>', 'maf\u200bsensor', 'maf%20sensor', 'http://x.y']) {
    assert.equal(speeroTerm(term), term);
  }
  assert.equal(normalizeAliasKey(null), '');
});

test('every entry is a plain, short, safe constant', () => {
  assert.ok(SPEERO_ALIASES.size >= 2);
  for (const [key, value] of SPEERO_ALIASES) {
    assert.equal(key, normalizeAliasKey(key));
    assert.match(value, /^[\p{L}\p{N} ]{2,40}$/u);
    assert.doesNotMatch(value, /https?:|\/\/|[<>"'%&=?]/);
  }
});

test('the Speero redirect uses the alias, once encoded, and ignores make/model/year', () => {
  assert.equal(speero('MAF Sensor', { make: 'Toyota', model: 'Camry', year: '2020' }).url, 'https://speero.net/search?q=Air%20Flow%20Sensor');
  assert.equal(speero('Transmission Mounts').url, 'https://speero.net/search?q=' + encodeURIComponent('كرسي قير'));
  assert.equal(speero('Spark Plugs').url, 'https://speero.net/search?q=Spark%20Plugs');
});

test('other stores do not use the Speero dictionary', () => {
  const web = buildDestination('web', { q: 'Toyota MAF Sensor', fields: { part: 'MAF Sensor', make: 'Toyota' } }, {});
  assert.match(decodeURIComponent(web.url), /Toyota MAF Sensor/);
  assert.doesNotMatch(decodeURIComponent(web.url), /Air Flow/);
});
