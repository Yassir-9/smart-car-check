path = "routes/diagnosis.js"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

edits = []

edits.append((
    "    const { description, car, obd_codes } = req.body;\n\n    if (!description) {\n      return res.status(400).json({ error: 'الوصف مطلوب' });\n    }",
    "    const { description, car, obd_codes, image } = req.body;\n\n    if (!description && !image) {\n      return res.status(400).json({ error: 'الوصف أو الصورة مطلوب' });\n    }",
))

edits.append((
    "هذا تشخيص أولي توجيهي فقط وليس بديلاً عن فحص فني متخصص، وضّح ذلك ضمن الشرح لو كانت الحالة تستدعي زيارة ورشة فوراً.`;",
    "هذا تشخيص أولي توجيهي فقط وليس بديلاً عن فحص فني متخصص، وضّح ذلك ضمن الشرح لو كانت الحالة تستدعي زيارة ورشة فوراً.\nلو أرفق المستخدم صورة للمبة تحذير في لوحة العدادات، حدد أي لمبة هي بدقة واشرح معناها ومستوى خطورتها ضمن possible_issue وexplanation.`;",
))

edits.append((
    "    const userMessage = `سيارة المستخدم: ${car?.brand|| ''} ${car?.model || ''} ${car?.year || ''}\nوصف المشكلة: ${description}${obdContext}`;",
    "    const userMessage = `سيارة المستخدم: ${car?.brand|| ''} ${car?.model || ''} ${car?.year || ''}\nوصف المشكلة: ${description || 'لا يوجد وصف نصي، المستخدم أرفق فقط صورة للمبة تحذير في لوحة العدادات ويريد معرفة معناها.'}${obdContext}`;",
))

edits.append((
    "    const response = await anthropic.messages.create({\n      model: 'claude-sonnet-4-6',\n      max_tokens: 1000,\n      system: systemPrompt,\n      messages: [{ role: 'user', content: userMessage}],\n    });",
    "    const messageContent = image && image.data\n      ? [\n          {\n            type: 'image',\n            source: {\n              type: 'base64',\n              media_type: image.media_type || 'image/jpeg',\n              data: image.data,\n            },\n          },\n          { type: 'text', text: userMessage },\n        ]\n      : userMessage;\n\n    const response = await anthropic.messages.create({\n      model: 'claude-sonnet-4-6',\n      max_tokens: 1000,\n      system: systemPrompt,\n      messages: [{ role: 'user', content: messageContent }],\n    });",
))

missing = [old for old, new in edits if old not in content]
if missing:
    print("⚠️ ما لقيت الأجزاء التالية بالضبط:")
    for m in missing:
        print("----")
        print(m[:150])
else:
    for old, new in edits:
        content = content.replace(old, new, 1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ تم تحديث diagnosis.js بنجاح (4 تعديلات)")
