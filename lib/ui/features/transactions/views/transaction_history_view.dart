import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gudang_mobile/core/constants/app_colors.dart';
import 'package:gudang_mobile/core/utils/formatters.dart';
import '../view_models/transaction_view_model.dart';

class TransactionHistoryView extends StatefulWidget {
  final String? productId;

  const TransactionHistoryView({super.key, this.productId});

  @override
  State<TransactionHistoryView> createState() => _TransactionHistoryViewState();
}

class _TransactionHistoryViewState extends State<TransactionHistoryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionViewModel>().fetchTransactions(
            productId: widget.productId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final trxVm = context.watch<TransactionViewModel>();
    final items = trxVm.filteredTransactions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi Stok'),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterButton('Semua', 'ALL', trxVm),
                const SizedBox(width: 8),
                _buildFilterButton('Masuk (IN)', 'IN', trxVm),
                const SizedBox(width: 8),
                _buildFilterButton('Keluar (OUT)', 'OUT', trxVm),
              ],
            ),
          ),

          // Transaction List
          Expanded(
            child: trxVm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.history_toggle_off, size: 54, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada riwayat transaksi',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Transaksi Inbound & Outbound akan tercatat di sini.',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => trxVm.fetchTransactions(productId: widget.productId),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final trx = items[i];
                            final isIn = trx.isInbound;

                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Direction Icon
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isIn
                                            ? AppColors.inbound.withValues(alpha: 0.12)
                                            : AppColors.outbound.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        isIn ? Icons.arrow_downward : Icons.arrow_upward,
                                        color: isIn ? AppColors.inbound : AppColors.outbound,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  trx.productName ?? 'Barang',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '${isIn ? '+' : '-'}${trx.quantity}',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  color: isIn ? AppColors.inbound : AppColors.outbound,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          if (trx.productSku != null) ...[
                                            Text(
                                              'SKU: ${trx.productSku}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontFamily: 'monospace',
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                          ],
                                          if (trx.notes != null && trx.notes!.isNotEmpty) ...[
                                            Text(
                                              '"${trx.notes}"',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                          ],
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.person_outline, size: 13, color: AppColors.textMuted),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    trx.userName ?? 'Staf Gudang',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (trx.createdAt != null)
                                                Text(
                                                  Formatters.formatDateTime(trx.createdAt!),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textMuted,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String type, TransactionViewModel vm) {
    final isSelected = vm.filterType == type;
    return Expanded(
      child: FilterChip(
        label: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
        selected: isSelected,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        showCheckmark: false,
        onSelected: (_) => vm.setFilterType(type),
      ),
    );
  }
}
