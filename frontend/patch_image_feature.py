path = "lib/screens/home_screen.dart"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

edits = []

# 1) imports
edits.append((
    "import 'dart:convert';\n",
    "import 'dart:convert';\nimport 'dart:io';\nimport 'package:image_picker/image_picker.dart';\n",
))

# 2) state variables
edits.append((
    "  final stt.SpeechToText _speech = stt.SpeechToText();\n  bool _isListening = false;\n  bool _speechAvailable = false;\n",
    "  final stt.SpeechToText _speech = stt.SpeechToText();\n  bool _isListening = false;\n  bool _speechAvailable = false;\n\n  final ImagePicker _imagePicker = ImagePicker();\n  File? _selectedImage;\n",
))

# 3) new methods, inserted right before _submitDiagnosis
edits.append((
    "  Future<void> _submitDiagnosis() async {\n",
    """  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('التقاط صورة'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('اختيار من المعرض'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 70,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الوصول للكاميرا/المعرض')),
        );
      }
    }
  }

  Future<void> _submitDiagnosis() async {
""",
))

# 4) validation: allow submit if image selected even with empty text
edits.append((
    "    if (_descriptionController.text.trim().isEmpty || _activeCar == null) return;",
    "    if ((_descriptionController.text.trim().isEmpty && _selectedImage == null) ||\n        _activeCar == null) return;",
))

# 5) include image (base64) in the request body
edits.append((
    """    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'description': _descriptionController.text.trim(),
          'car': {
            'brand': _activeCar!.brand,
            'model': _activeCar!.model,
            'year': _activeCar!.year,
          },
        }),
      );""",
    """    try {
      String? imageBase64;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        imageBase64 = base64Encode(bytes);
      }

      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'description': _descriptionController.text.trim(),
          'car': {
            'brand': _activeCar!.brand,
            'model': _activeCar!.model,
            'year': _activeCar!.year,
          },
          if (imageBase64 != null)
            'image': {
              'data': imageBase64,
              'media_type': 'image/jpeg',
            },
        }),
      );""",
))

# 6) UI: image preview / picker button, right before the submit button's leading SizedBox(height:16)
edits.append((
    "                const SizedBox(height: 16),\n\n                SizedBox(\n                  height: 52,\n                  child: ElevatedButton.icon(\n                    onPressed: _isLoading ? null : _submitDiagnosis,",
    """                const SizedBox(height: 12),
                if (_selectedImage != null)
                  Stack(
                    alignment: Alignment.topLeft,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 16,
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () =>
                                setState(() => _selectedImage = null),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _showImageSourceSheet,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('أضف صورة للمبة التحذير (اختياري)'),
                  ),
                const SizedBox(height: 16),

                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitDiagnosis,""",
))

missing = [old for old, new in edits if old not in content]
if missing:
    print("⚠️ ما لقيت الأجزاء التالية بالضبط - ما راح أعدل أي شي:")
    for m in missing:
        print("----")
        print(m[:150])
else:
    for old, new in edits:
        content = content.replace(old, new, 1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ تم تحديث home_screen.dart بنجاح (6 تعديلات)")
