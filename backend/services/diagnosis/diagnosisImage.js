const ALLOWED_IMAGE_TYPES = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/heic',
  'image/heif',
]);
const MAX_IMAGE_BYTES = 7 * 1024 * 1024;

function normalizeDiagnosisImage(image) {
  if (image == null) return { image: null };
  if (!image || typeof image !== 'object' || Array.isArray(image)) {
    return { error: 'بيانات الصورة غير صالحة' };
  }
  const mediaType = String(image.media_type || '').trim().toLowerCase();
  const data = typeof image.data === 'string' ? image.data.trim() : '';
  if (!ALLOWED_IMAGE_TYPES.has(mediaType)) {
    return { error: 'صيغة الصورة غير مدعومة. استخدم JPEG أو PNG أو WebP أو HEIC' };
  }
  if (!data || data.length % 4 !== 0 || !/^[a-zA-Z0-9+/]+={0,2}$/.test(data)) {
    return { error: 'بيانات الصورة غير صالحة' };
  }
  const bytes = Buffer.from(data, 'base64');
  if (bytes.toString('base64') !== data) {
    return { error: 'بيانات الصورة غير صالحة' };
  }
  if (bytes.length === 0 || bytes.length > MAX_IMAGE_BYTES) {
    return { error: 'حجم الصورة غير صالح أو يتجاوز الحد المسموح' };
  }
  return { image: { data, media_type: mediaType } };
}

module.exports = { normalizeDiagnosisImage, ALLOWED_IMAGE_TYPES, MAX_IMAGE_BYTES };
