// Small dictionary: part term (English, as the AI writes it) -> the term that gives the
// best results on speero.net. ONLY ASCII terms checked by hand in a browser (first 8 results
// relevant, 2026-11-17) belong here. Do not add a guess; see
// BUILDS-20261116/speero-aliases-20261117.md for what was tried and rejected.
//
// Keys are lowercase with single spaces. Values are fixed constants (never user text).
const SPEERO_ALIASES = new Map([
  // "MAF Sensor" returned crankshaft sensors (0 of 8); "Air Flow Sensor" returns air-flow sensors.
  ['maf sensor', 'Air Flow Sensor'],
  // Fixed rule: every term sent to Speero is ASCII only. Arabic search text shows up encoded and
  // broken on iPhone, so no Arabic entry belongs here (a test enforces it).
]);

function normalizeAliasKey(term) {
  return String(term ?? '').normalize('NFKC').trim().toLowerCase().replace(/\s+/g, ' ');
}

// Returns the Speero-specific term, or the original text untouched when there is no entry.
function speeroTerm(term) {
  if (typeof term !== 'string') return term;
  const alias = SPEERO_ALIASES.get(normalizeAliasKey(term));
  return alias === undefined ? term : alias;
}

module.exports = { SPEERO_ALIASES, speeroTerm, normalizeAliasKey };
