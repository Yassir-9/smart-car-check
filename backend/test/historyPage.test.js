const test = require('node:test');
const assert = require('node:assert/strict');
const { parseHistoryQuery, readHistoryPage, DEFAULT_HISTORY_LIMIT, MAX_HISTORY_LIMIT } = require('../services/history/historyPage');

test('history query defaults to the latest 50 and caps at 100', () => {
  assert.deepEqual(parseHistoryQuery({}), { limit: DEFAULT_HISTORY_LIMIT, before: null });
  assert.equal(DEFAULT_HISTORY_LIMIT, 50);
  assert.equal(parseHistoryQuery({ limit: '20' }).limit, 20);
  assert.equal(parseHistoryQuery({ limit: '5000' }).limit, MAX_HISTORY_LIMIT);
  for (const bad of ['0', '-1', 'abc', '']) assert.equal(parseHistoryQuery({ limit: bad }).limit, 50);
});

test('before cursor must be a valid date string', () => {
  assert.equal(parseHistoryQuery({ before: '2026-11-16T10:00:00.000Z' }).before, '2026-11-16T10:00:00.000Z');
  assert.equal(parseHistoryQuery({ before: 'nope' }).before, null);
  assert.equal(parseHistoryQuery({ before: ['x'] }).before, null);
});

test('readHistoryPage orders newest first, applies the cursor and the limit', async () => {
  const calls = [];
  const query = {
    orderBy(field, dir) { calls.push(['orderBy', field, dir]); return query; },
    startAfter(value) { calls.push(['startAfter', value]); return query; },
    limit(n) { calls.push(['limit', n]); return query; },
    async get() { return { docs: [{ data: () => ({ id: 'a' }) }, { data: () => ({ id: 'b' }) }] }; },
  };
  const db = { collection: (c) => ({ doc: (d) => ({ collection: (sub) => { calls.push(['path', c, d, sub]); return query; } }) }) };
  const rows = await readHistoryPage(db, 'u1', { limit: 50, before: '2026-01-01T00:00:00.000Z' });
  assert.deepEqual(rows, [{ id: 'a' }, { id: 'b' }]);
  assert.deepEqual(calls, [
    ['path', 'users', 'u1', 'history'],
    ['orderBy', 'timestamp', 'desc'],
    ['startAfter', '2026-01-01T00:00:00.000Z'],
    ['limit', 50],
  ]);
});
