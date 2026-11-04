import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:gudang_mobile/core/constants/app_colors.dart';
import 'package:gudang_mobile/core/utils/pdf_generator.dart';
import 'package:gudang_mobile/data/models/product_model.dart';

class QrLabelPreviewView extends StatelessWidget {
  final ProductModel product;

  const QrLabelPreviewView({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Label QR: ${product.sku}'),
        actions: [
          IconButton(
            tooltip: 'Bagikan Dokumen PDF',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => PdfGenerator.shareProductLabel(product),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pratinjau label standar ukuran 80mm x 55mm untuk printer thermal/label.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PdfPreview(
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              build: (format) => PdfGenerator.generateProductLabel(product),
              pdfFileName: 'Label_${product.sku}.pdf',
            ),
          ),
        ],
      ),
    );
  }
}
