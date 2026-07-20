import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:barcode/barcode.dart';
import 'package:printing/printing.dart';
import '../models/car_model.dart';

class PdfService {
  static Future<void> shareDiagnosisPdf({
    required Map<String, dynamic> result,
    required CarModel? car,
    required String description,
  }) async {
    final fontData = await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);
    final boldTtf = pw.Font.ttf(boldFontData);

    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/icon/icon.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      logoImage = null;
    }

    final severity = result['severity'] ?? 'غير محددة';
    final issue = result['possible_issue'] ?? '';
    final explanation = result['explanation'] ?? '';
    final confidenceScore = result['confidence_score'];
    final confidenceReason = result['confidence_reason'];
    final canDrive = result['can_drive'];
    final recommendations = result['recommendations'] != null
        ? List<String>.from(result['recommendations'])
        : <String>[];
    final cost = result['estimated_cost'];
    final diagnosisId = result['diagnosis_id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

    List<Map<String, dynamic>> parts = [];
    if (result['matched_parts'] != null) {
      parts.addAll(List<Map<String, dynamic>>.from(result['matched_parts']));
    }
    if (parts.isEmpty && result['external_search'] != null &&
        result['external_search']['found'] == true) {
      final suggestions = result['external_search']['suggestions'];
      if (suggestions != null) {
        parts.addAll(List<Map<String, dynamic>>.from(suggestions).map((s) => {
              'partName': s['name'],
              'price': s['estimated_price'],
              'sellerPhone': s['store_name'],
            }));
      }
    }

    PdfColor severityColor;
    switch (severity) {
      case 'عالية':
        severityColor = PdfColor.fromInt(0xFFD32F2F);
        break;
      case 'متوسطة':
        severityColor = PdfColor.fromInt(0xFFF57C00);
        break;
      case 'منخفضة':
        severityColor = PdfColor.fromInt(0xFF388E3C);
        break;
      default:
        severityColor = PdfColors.grey;
    }

    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final qrData =
        'Smart Car Check\nرقم التقرير: $diagnosisId\nالتاريخ: $dateStr\nالمشكلة: $issue\nالخطورة: $severity\nالسيارة: ${car?.label ?? 'غير محددة'}';

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF1E3A5F),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  width: double.infinity,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (logoImage != null) ...[
                        pw.Container(
                          width: 32,
                          height: 32,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            image: pw.DecorationImage(image: logoImage, fit: pw.BoxFit.cover),
                          ),
                        ),
                        pw.SizedBox(width: 10),
                      ],
                      pw.Text(
                        'تقرير تشخيص السيارة الذكي',
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 20, font: boldTtf),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text('رقم التقرير: $diagnosisId  |  التاريخ: $dateStr',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                pw.SizedBox(height: 12),
                if (car != null)
                  pw.Text('السيارة: ${car.label}',
                      style: pw.TextStyle(fontSize: 13, font: boldTtf)),
                pw.SizedBox(height: 6),
                pw.Text('وصف المشكلة: $description',
                    style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(issue,
                    style: pw.TextStyle(fontSize: 16, font: boldTtf)),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: severityColor,
                        borderRadius: pw.BorderRadius.circular(20),
                      ),
                      child: pw.Text('الخطورة: $severity',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 11, font: boldTtf)),
                    ),
                    if (confidenceScore != null) ...[
                      pw.SizedBox(width: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blueGrey100,
                          borderRadius: pw.BorderRadius.circular(20),
                        ),
                        child: pw.Text('نسبة الثقة: $confidenceScore%',
                            style: pw.TextStyle(color: PdfColors.blueGrey900, fontSize: 11, font: boldTtf)),
                      ),
                    ],
                  ],
                ),
                if (confidenceReason != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(confidenceReason,
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ],
                if (canDrive != null) ...[
                  pw.SizedBox(height: 10),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: severityColor.shade(0.9),
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: severityColor),
                    ),
                    child: pw.Text(canDrive,
                        style: pw.TextStyle(fontSize: 11, font: boldTtf, color: severityColor)),
                  ),
                ],
                pw.SizedBox(height: 14),
                pw.Text('التفسير:',
                    style: pw.TextStyle(fontSize: 13, font: boldTtf)),
                pw.SizedBox(height: 6),
                pw.Text(explanation,
                    style: const pw.TextStyle(fontSize: 12, lineSpacing: 3)),
                if (recommendations.isNotEmpty) ...[
                  pw.SizedBox(height: 14),
                  pw.Text('التوصيات:',
                      style: pw.TextStyle(fontSize: 13, font: boldTtf)),
                  pw.SizedBox(height: 6),
                  ...recommendations.map(
                    (r) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text('•  $r',
                          style: const pw.TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
                if (parts.isNotEmpty) ...[
                  pw.SizedBox(height: 14),
                  pw.Text('القطع المطلوبة:',
                      style: pw.TextStyle(fontSize: 13, font: boldTtf)),
                  pw.SizedBox(height: 6),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('القطعة', style: pw.TextStyle(fontSize: 10, font: boldTtf)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('السعر', style: pw.TextStyle(fontSize: 10, font: boldTtf)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('المصدر', style: pw.TextStyle(fontSize: 10, font: boldTtf)),
                          ),
                        ],
                      ),
                      ...parts.take(6).map((p) => pw.TableRow(children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('${p['partName'] ?? ''}', style: const pw.TextStyle(fontSize: 10)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('${p['price'] ?? '-'}', style: const pw.TextStyle(fontSize: 10)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('${p['sellerPhone'] ?? '-'}', style: const pw.TextStyle(fontSize: 10)),
                            ),
                          ])),
                    ],
                  ),
                ],
                if (cost != null && cost != 'null') ...[
                  pw.SizedBox(height: 14),
                  pw.Divider(),
                  pw.Text('التكلفة التقديرية: $cost',
                      style: const pw.TextStyle(fontSize: 12)),
                ],
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.orange50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.orange200),
                  ),
                  child: pw.Text(
                    'هذا تشخيص أولي توجيهي بالذكاء الاصطناعي، وليس بديلاً عن فحص فني معتمد.',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('امسح الرمز للتحقق من محتوى التقرير',
                              style: pw.TextStyle(fontSize: 10, font: boldTtf)),
                          pw.SizedBox(height: 3),
                          pw.Text('رقم التقرير: $diagnosisId',
                              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        ],
                      ),
                    ),
                    pw.BarcodeWidget(
                      barcode: Barcode.qrCode(),
                      data: qrData,
                      width: 70,
                      height: 70,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'تشخيص_السيارة.pdf',
    );
  }
}
