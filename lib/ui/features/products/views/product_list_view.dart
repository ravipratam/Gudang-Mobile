import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gudang_mobile/core/constants/app_colors.dart';
import 'package:gudang_mobile/ui/core/stock_badge.dart';
import '../view_models/product_view_model.dart';
import '../../auth/view_models/auth_view_model.dart';
import 'product_detail_view.dart';
import 'product_form_view.dart';

class ProductListView extends StatefulWidget {
  const ProductListView({super.key});

  @override
  State<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends State<ProductListView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ProductViewModel>();
      vm.fetchCategories();
      vm.fetchProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productVm = context.watch<ProductViewModel>();
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
        title: const Text('Katalog Barang Gudang'),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Tambah Barang',
              icon: const Icon(Icons.add_circle, color: AppColors.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductFormView()),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (val) => productVm.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Cari nama barang, SKU, atau rak...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              productVm.setSearchQuery('');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),

                // Category Chips & Low Stock Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Low Stock Quick Filter
                      FilterChip(
                        selected: productVm.filterLowStockOnly,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: productVm.filterLowStockOnly ? Colors.white : AppColors.critical,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Stok Menipis',
                              style: TextStyle(
                                fontSize: 12,
                                color: productVm.filterLowStockOnly ? Colors.white : AppColors.critical,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        selectedColor: AppColors.critical,
                        checkmarkColor: Colors.white,
                        backgroundColor: const Color(0xFFFEE2E2),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        onSelected: (_) => productVm.toggleLowStockFilter(),
                      ),
                      const SizedBox(width: 8),

                      // All Categories Chip
                      ChoiceChip(
                        label: const Text('Semua Kategori', style: TextStyle(fontSize: 12)),
                        selected: productVm.selectedCategoryId == null,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: productVm.selectedCategoryId == null ? Colors.white : AppColors.textPrimary,
                        ),
                        onSelected: (_) => productVm.setSelectedCategory(null),
                      ),
                      const SizedBox(width: 8),

                      // Dynamic Categories
                      ...productVm.categories.map((cat) {
                        final isSelected = productVm.selectedCategoryId == cat.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(cat.name, style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                            onSelected: (_) => productVm.setSelectedCategory(cat.id),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: productVm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : productVm.products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 54, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'Tidak ada data barang ditemukan',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isAdmin
                                  ? 'Coba ubah kata kunci pencarian atau tambah barang baru.'
                                  : 'Coba ubah kata kunci pencarian barang.',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            if (isAdmin) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ProductFormView()),
                                  );
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Tambah Barang Sekarang'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => productVm.fetchProducts(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: productVm.products.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final product = productVm.products[index];
                            return Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailView(product: product),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Product icon container
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.qr_code,
                                          color: AppColors.primary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Main info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.background,
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(
                                                      color: AppColors.cardBorder,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    product.sku,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: 'monospace',
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                                if (product.categoryName != null) ...[
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '• ${product.categoryName}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              product.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.place_outlined,
                                                  size: 13,
                                                  color: AppColors.textMuted,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  product.location ?? 'Lokasi belum diatur',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Stock badge
                                      StockBadge(
                                        stock: product.stock,
                                        minStock: product.minStock,
                                        compact: true,
                                      ),
                                    ],
                                  ),
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
}
