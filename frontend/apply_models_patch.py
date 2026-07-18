path = "lib/screens/cars_screen.dart"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

edits = []

# 1) import
edits.append((
    "import '../services/car_service.dart';\n",
    "import '../services/car_service.dart';\nimport '../data/car_models_data.dart';\n",
))

# 2) variable declarations block
edits.append((
    """    String selectedBrand = existing != null && _brands.contains(existing.brand)
        ? existing.brand
        : (existing != null ? 'أخرى' : _brands.first);
    final customBrandController = TextEditingController(
      text: existing != null && !_brands.contains(existing.brand)
          ? existing.brand
          : '',
    );
    final modelController = TextEditingController(text: existing?.model ?? '');
    int selectedYear = existing?.year ?? currentYear;
""",
    """    String selectedBrand = existing != null && _brands.contains(existing.brand)
        ? existing.brand
        : (existing != null ? 'أخرى' : _brands.first);
    final customBrandController = TextEditingController(
      text: existing != null && !_brands.contains(existing.brand)
          ? existing.brand
          : '',
    );
    final brandModelsInit =
        CarModelsData.modelsByBrand[selectedBrand] ?? const <String>[];
    String selectedModel = existing != null && brandModelsInit.contains(existing.model)
        ? existing.model
        : 'أخرى';
    final modelController = TextEditingController(
      text: existing != null && !brandModelsInit.contains(existing.model)
          ? existing.model
          : '',
    );
    int selectedYear = existing?.year ?? currentYear;
""",
))

# 3) the model field widget
edits.append((
    """                const SizedBox(height: 12),
                TextField(
                  controller: modelController,
                  decoration: const InputDecoration(labelText: 'الموديل'),
                ),
                const SizedBox(height: 12),
                const Text('سنة الصنع',""",
    """                const SizedBox(height: 12),
                const Text('الموديل',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Builder(builder: (context) {
                  final models =
                      CarModelsData.modelsByBrand[selectedBrand] ?? const <String>[];
                  if (models.isEmpty) {
                    return TextField(
                      controller: modelController,
                      decoration:
                          const InputDecoration(labelText: 'اكتب اسم الموديل'),
                    );
                  }
                  final dropdownItems = [...models, 'أخرى'];
                  if (!dropdownItems.contains(selectedModel)) {
                    selectedModel = dropdownItems.first;
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedModel,
                        isExpanded: true,
                        items: dropdownItems
                            .map((m) =>
                                DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedModel = val);
                          }
                        },
                      ),
                      if (selectedModel == 'أخرى') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: modelController,
                          decoration: const InputDecoration(
                              labelText: 'اكتب اسم الموديل'),
                        ),
                      ],
                    ],
                  );
                }),
                const SizedBox(height: 12),
                const Text('سنة الصنع',""",
))

# 4) validation before closing dialog
edits.append((
    """              onPressed: () {
                if (modelController.text.trim().isEmpty) return;
                if (selectedBrand == 'أخرى' &&
                    customBrandController.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(context, true);
              },""",
    """              onPressed: () {
                final modelsForBrand =
                    CarModelsData.modelsByBrand[selectedBrand] ?? const <String>[];
                final modelValue = modelsForBrand.isEmpty
                    ? modelController.text.trim()
                    : (selectedModel == 'أخرى'
                        ? modelController.text.trim()
                        : selectedModel);
                if (modelValue.isEmpty) return;
                if (selectedBrand == 'أخرى' &&
                    customBrandController.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(context, true);
              },""",
))

# 5) final model extraction
edits.append((
    """    final brand = selectedBrand == 'أخرى'
        ? customBrandController.text.trim()
        : selectedBrand;
    final model = modelController.text.trim();
    final year = selectedYear;""",
    """    final brand = selectedBrand == 'أخرى'
        ? customBrandController.text.trim()
        : selectedBrand;
    final brandModelsFinal =
        CarModelsData.modelsByBrand[selectedBrand] ?? const <String>[];
    final model = brandModelsFinal.isEmpty
        ? modelController.text.trim()
        : (selectedModel == 'أخرى'
            ? modelController.text.trim()
            : selectedModel);
    final year = selectedYear;""",
))

missing = [old for old, new in edits if old not in content]
if missing:
    print("⚠️ ما لقيت الأجزاء التالية بالضبط - ما راح أعدل أي شي:")
    for m in missing:
        print("----")
        print(m[:120])
else:
    for old, new in edits:
        content = content.replace(old, new, 1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ تم تحديث cars_screen.dart بنجاح (5 تعديلات)")
