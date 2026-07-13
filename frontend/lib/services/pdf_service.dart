import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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

    final severity = result['severity'] ?? 'غير محددة';
    final issue = result['possible_issue'] ?? '';
    final explanation = result['explanation'] ?? '';
    final recommendations = result['recommendations'] != null
        ? List<String>.from(result['recommendations'])
        : <String>[];
    final cost = result['estimated_cost'];

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
                  child: pw.Text(
                    'تقرير تشخيص السيارة الذكي',
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 20,
                        font: boldTtf),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 16),
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
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: severityColor,
                    borderRadius: pw.BorderRadius.circular(20),
                  ),
                  child: pw.Text('الخطورة: $severity',
                      style: pw.TextStyle(
                          color: PdfColors.white, fontSize: 11, font: boldTtf)),
                ),
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
                if (cost != null && cost != 'null') ...[
                  pw.SizedBox(height: 14),
                  pw.Divider(),
                  pw.Text('التكلفة التقديرية: $cost',
                      style: const pw.TextStyle(fontSize: 12)),
                ],
                pw.SizedBox(height: 24),
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
