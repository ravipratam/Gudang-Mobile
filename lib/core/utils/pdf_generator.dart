import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/product_model.dart';
import 'formatters.dart';

class PdfGenerator {
  /// Generate PDF document bytes for a single product QR label
  static Future<Uint8List> generateProductLabel(ProductModel product) async {
    final pdf = pw.Document();

    // Standard warehouse label size: 80mm x 50mm or roll label
    const pageFormat = PdfPageFormat(
      80 * PdfPageFormat.mm,
      55 * PdfPageFormat.mm,
      marginAll: 4 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey800, width: 1.2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // QR Code
                pw.Container(
                  width: 38 * PdfPageFormat.mm,
                  height: 38 * PdfPageFormat.mm,
                  alignment: pw.Alignment.center,
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: product.sku,
                    width: 36 * PdfPageFormat.mm,
                    height: 36 * PdfPageFormat.mm,
                  ),
                ),
                pw.SizedBox(width: 8),
                // Product Information
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        'WMS LABEL',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        product.name,
                        maxLines: 2,
                        overflow: pw.TextOverflow.clip,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'SKU: ${product.sku}',
                        style: const pw.TextStyle(
                          fontSize: 8,
                        ),
                      ),
                      if (product.location != null && product.location!.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Lokasi: ${product.location}',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey900,
                          ),
                        ),
                      ],
                      pw.SizedBox(height: 4),
                      pw.Text(
                        Formatters.formatDate(DateTime.now()),
                        style: const pw.TextStyle(
                          fontSize: 6,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Trigger direct printing dialog via system / Bluetooth printer
  static Future<void> printProductLabel(ProductModel product) async {
    final pdfBytes = await generateProductLabel(product);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Label_${product.sku}.pdf',
    );
  }

  /// Share label PDF to other apps (WhatsApp, Email, etc.)
  static Future<void> shareProductLabel(ProductModel product) async {
    final pdfBytes = await generateProductLabel(product);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Label_${product.sku}.pdf',
    );
  }
}
