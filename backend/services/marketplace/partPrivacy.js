const PUBLIC_PART_FIELDS = Object.freeze([
  'partName',
  'carBrand',
  'carModel',
  'price',
  'notes',
  'ownerId',
  'oemNumber',
  'imageBase64',
  'condition',
  'partBrand',
  'createdAt',
]);

function pickFields(source, fields) {
  return Object.fromEntries(
    fields
      .filter((field) => Object.hasOwn(source, field))
      .map((field) => [field, source[field]]),
  );
}

function toPublicPart(id, data = {}) {
  return { id, ...pickFields(data, PUBLIC_PART_FIELDS) };
}

// Temporary rollout DTO used only by the compatibility deployment. The final
// production router uses toPublicPart and removes contact data publicly.
function toCompatibilityPart(id, data = {}) {
  return {
    ...toPublicPart(id, data),
    sellerPhone: typeof data.sellerPhone === 'string' ? data.sellerPhone : '',
  };
}

function toOwnerPart(id, data = {}) {
  return {
    ...toPublicPart(id, data),
    sellerPhone: typeof data.sellerPhone === 'string' ? data.sellerPhone : '',
  };
}

function toBuyerOrder(id, data = {}) {
  return {
    id,
    status: data.status,
    totalAmount: data.totalAmount,
    createdAt: data.createdAt,
    paidAt: data.paidAt,
    items: Array.isArray(data.items)
      ? data.items.map(({ sellerPhone, ...item }) => item)
      : [],
  };
}

function toSellerOrder(id, data = {}, sellerId) {
  const items = Array.isArray(data.items)
    ? data.items
        .filter((item) => item.sellerId === sellerId)
        .map(({ sellerPhone, ...item }) => item)
    : [];
  return { id, status: data.status, createdAt: data.createdAt, paidAt: data.paidAt, items };
}

function sanitizeDiagnosisHistoryEntry(entry = {}) {
  const result = entry.result && typeof entry.result === 'object' ? entry.result : null;
  if (!result || !Array.isArray(result.matched_parts)) return entry;
  return {
    ...entry,
    result: {
      ...result,
      matched_parts: result.matched_parts.map((part) => toPublicPart(part.id, part)),
    },
  };
}

module.exports = {
  PUBLIC_PART_FIELDS,
  toPublicPart,
  toCompatibilityPart,
  toOwnerPart,
  toBuyerOrder,
  toSellerOrder,
  sanitizeDiagnosisHistoryEntry,
};
