String resolveImageMimeType({
  required String path,
  String? reportedMimeType,
}) {
  final normalizedMimeType = reportedMimeType?.trim().toLowerCase();
  if (normalizedMimeType != null &&
      normalizedMimeType.startsWith('image/') &&
      normalizedMimeType.length > 'image/'.length) {
    return normalizedMimeType;
  }

  final normalizedPath = path.toLowerCase().split(RegExp(r'[?#]')).first;
  if (normalizedPath.endsWith('.png')) {
    return 'image/png';
  }
  if (normalizedPath.endsWith('.webp')) {
    return 'image/webp';
  }
  if (normalizedPath.endsWith('.gif')) {
    return 'image/gif';
  }
  if (normalizedPath.endsWith('.heic')) {
    return 'image/heic';
  }
  if (normalizedPath.endsWith('.heif')) {
    return 'image/heif';
  }
  if (normalizedPath.endsWith('.bmp')) {
    return 'image/bmp';
  }

  // ImagePicker commonly returns JPEG camera/gallery images without a MIME
  // value on some platforms. JPEG is the safest fallback for those cases.
  return 'image/jpeg';
}
