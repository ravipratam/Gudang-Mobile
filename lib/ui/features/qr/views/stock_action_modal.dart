import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gudang_mobile/core/constants/app_colors.dart';
import 'package:gudang_mobile/core/utils/formatters.dart';
import 'package:gudang_mobile/ui/core/custom_button.dart';
import 'package:gudang_mobile/ui/core/custom_text_field.dart';
import 'package:gudang_mobile/data/models/product_model.dart';
import '../view_models/scanner_view_model.dart';

class StockActionModal extends StatefulWidget {
  final ProductModel product;
  final String initialType; // 'IN' or 'OUT'

  const StockActionModal({
    super.key,
    required this.product,
    this.initialType = 'IN',
  });

  @override
  State<StockActionModal> createState() => _StockActionModalState();
}

class _StockActionModalState extends State<StockActionModal> {
  late String _type;
  final _qtyController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType.toUpperCase();
    _qtyController.addListener(_onQtyTextChanged);
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onQtyTextChanged() {
    final parsed = int.tryParse(_qtyController.text);
    if (parsed != null && parsed != _qty) {
      setState(() => _qty = parsed);
    }
  }

  void _changeQty(int delta) {
    final next = (_qty + delta).clamp(1, 999999);
    setState(() {
      _qty = next;
      _qtyController.text = next.toString();
    });
  }

  void _onSubmit() async {
    if (_qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah barang harus lebih dari 0'),
          backgroundColor: AppColors.critical,
        ),
      );
      return;
    }

    if (_type == 'OUT' && _qty > widget.product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stok tidak mencukupi! Stok saat ini ${widget.product.stock}, diminta $_qty.',
          ),
          backgroundColor: AppColors.critical,
        ),
      );
      return;
    }

    final scannerVm = context.read<ScannerViewModel>();
    final success = await scannerVm.executeStockTransaction(
      productId: widget.product.id,
      type: _type,
      quantity: _qty,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _type == 'IN'
                ? 'Berhasil menambah +$_qty unit ke stok "${widget.product.name}"'
                : 'Berhasil mengeluarkan -$_qty unit dari stok "${widget.product.name}"',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted && scannerVm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(scannerVm.errorMessage!),
          backgroundColor: AppColors.critical,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannerVm = context.watch<ScannerViewModel>();
    final bool isInbound = _type == 'IN';
    final int predictedStock = isInbound
        ? widget.product.stock + _qty
        : widget.product.stock - _qty;
    final bool hasStockError = !isInbound && _qty > widget.product.stock;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isInbound ? 'Pencatatan Barang Masuk' : 'Pencatatan Barang Keluar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isInbound ? AppColors.inbound : AppColors.outbound,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Product Info Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SKU: ${widget.product.sku}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          'Stok Saat Ini: ${Formatters.formatNumber(widget.product.stock)} Unit',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Segmented Type Selector
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _type = 'IN'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isInbound ? AppColors.inbound.withValues(alpha: 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isInbound ? AppColors.inbound : AppColors.cardBorder,
                            width: isInbound ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 16,
                              color: isInbound ? AppColors.inbound : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Masuk (IN)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isInbound ? AppColors.inbound : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _type = 'OUT'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !isInbound ? AppColors.outbound.withValues(alpha: 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: !isInbound ? AppColors.outbound : AppColors.cardBorder,
                            width: !isInbound ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 16,
                              color: !isInbound ? AppColors.outbound : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Keluar (OUT)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: !isInbound ? AppColors.outbound : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Quantity Stepper
              const Text(
                'Jumlah Perubahan Stok',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: AppColors.textPrimary,
                    ),
                    onPressed: _qty > 1 ? () => _changeQty(-1) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: AppColors.textPrimary,
                    ),
                    onPressed: () => _changeQty(1),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Quick Qty Pills (+5, +10, +50, +100)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [5, 10, 25, 50, 100].map((step) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text('+$step', style: const TextStyle(fontSize: 12)),
                        onPressed: () => _changeQty(step),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Predicted Final Stock Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: hasStockError ? const Color(0xFFFEE2E2) : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasStockError ? AppColors.critical : AppColors.cardBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      hasStockError ? 'Stok Tidak Cukup!' : 'Estimasi Stok Akhir:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasStockError ? AppColors.critical : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${widget.product.stock} ${isInbound ? '+' : '-'} $_qty = $predictedStock Unit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: hasStockError ? AppColors.critical : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Transaction Notes
              CustomTextField(
                label: 'Catatan / Alasan Transaksi (Opsional)',
                hint: 'Contoh: Restock Supplier, PO #98231, Barang Rusak, dsb.',
                controller: _notesController,
                maxLines: 2,
              ),
              const SizedBox(height: 22),

              // Submit Button
              CustomButton(
                text: isInbound
                    ? 'Konfirmasi Tambah Stok (+$_qty)'
                    : 'Konfirmasi Keluar Stok (-$_qty)',
                color: isInbound ? AppColors.inbound : AppColors.outbound,
                icon: Icons.check,
                isLoading: scannerVm.isProcessing,
                onPressed: hasStockError ? null : _onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
