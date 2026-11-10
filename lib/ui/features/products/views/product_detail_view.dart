import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gudang_mobile/core/constants/app_colors.dart';
import 'package:gudang_mobile/core/utils/formatters.dart';
import 'package:gudang_mobile/ui/core/custom_button.dart';
import 'package:gudang_mobile/ui/core/stock_badge.dart';
import 'package:gudang_mobile/data/models/product_model.dart';
import '../view_models/product_view_model.dart';
import '../../auth/view_models/auth_view_model.dart';
import 'product_form_view.dart';
import '../../qr/views/qr_label_preview_view.dart';
import '../../qr/views/stock_action_modal.dart';

class ProductDetailView extends StatefulWidget {
  final ProductModel product;

  const ProductDetailView({super.key, required this.product});

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  late ProductModel _product;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  void _openStockAction(String type) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StockActionModal(
        product: _product,
        initialType: type,
      ),
    );

    if (result == true && mounted) {
      // Reload product from repository
      final productVm = context.read<ProductViewModel>();
      await productVm.fetchProducts();
      final updated = productVm.products.firstWhere(
        (p) => p.id == _product.id,
        orElse: () => _product,
      );
      setState(() => _product = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    AuthViewModel? authVm;
    try {
      authVm = context.watch<AuthViewModel>();
    } catch (_) {
      authVm = null;
    }
    final isAdmin = authVm?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Barang'),
        actions: [
          if (isAdmin) ...[
            IconButton(
              tooltip: 'Ubah Data',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final updated = await Navigator.push<ProductModel>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductFormView(productToEdit: _product),
                  ),
                );
                if (updated != null && mounted) {
                  setState(() => _product = updated);
                }
              },
            ),
            IconButton(
              tooltip: 'Hapus Barang',
              icon: const Icon(Icons.delete_outline, color: AppColors.critical),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hapus Barang?'),
                    content: Text('Anda yakin ingin menghapus "${_product.name}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.critical),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  final nav = Navigator.of(context);
                  final prodVm = context.read<ProductViewModel>();
                  await prodVm.deleteProduct(_product.id);
                  if (mounted) nav.pop();
                }
              },
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // QR Code Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: QrImageView(
                      data: _product.sku,
                      version: QrVersions.auto,
                      size: 160.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _product.sku,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontFamily: 'monospace',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QrLabelPreviewView(product: _product),
                        ),
                      );
                    },
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('Cetak / Pratinjau Label QR'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Product Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _product.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      StockBadge(
                        stock: _product.stock,
                        minStock: _product.minStock,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    icon: Icons.category_outlined,
                    label: 'Kategori',
                    value: _product.categoryName ?? 'Tidak Berkategori',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.place_outlined,
                    label: 'Lokasi Rak Gudang',
                    value: _product.location ?? 'Belum ditentukan',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.all_inbox_outlined,
                    label: 'Stok Saat Ini',
                    value: '${Formatters.formatNumber(_product.stock)} Unit',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.warning_amber_rounded,
                    label: 'Batas Minimum Stok',
                    value: '${Formatters.formatNumber(_product.minStock)} Unit',
                  ),
                  if (_product.createdAt != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Tanggal Didaftarkan',
                      value: Formatters.formatDate(_product.createdAt!),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stock IN / OUT Action Buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Barang Masuk (+)',
                    icon: Icons.add_circle_outline,
                    color: AppColors.inbound,
                    onPressed: () => _openStockAction('IN'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Barang Keluar (-)',
                    icon: Icons.remove_circle_outline,
                    color: AppColors.outbound,
                    onPressed: () => _openStockAction('OUT'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
