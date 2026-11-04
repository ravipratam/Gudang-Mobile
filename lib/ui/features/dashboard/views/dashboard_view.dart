import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gudang_mobile/core/constants/app_colors.dart';
import 'package:gudang_mobile/core/utils/formatters.dart';
import 'package:gudang_mobile/ui/core/stock_badge.dart';
import '../view_models/dashboard_view_model.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../auth/views/auth_gate.dart';
import '../../products/views/product_list_view.dart';
import '../../products/views/product_form_view.dart';
import '../../products/views/product_detail_view.dart';
import '../../qr/views/qr_scanner_view.dart';
import 'package:gudang_mobile/ui/features/qr/view_models/scanner_view_model.dart';
import '../../transactions/views/transaction_history_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardViewModel>().loadDashboard();
      context.read<AuthViewModel>().refreshProfile();
    });
  }

  void _onBottomNavTapped(int index) {
    if (index == 2) {
      // Tap Center Scan QR
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const QrScannerView(mode: ScannerMode.search),
        ),
      ).then((_) {
        if (mounted) context.read<DashboardViewModel>().loadDashboard();
      });
      return;
    }

    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : (_currentIndex > 2 ? _currentIndex - 1 : _currentIndex),
        children: const [
          _DashboardHomeContent(),
          ProductListView(),
          TransactionHistoryView(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onBottomNavTapped,
        backgroundColor: Colors.white,
        elevation: 2,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: AppColors.primary),
            label: 'Barang',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 28),
            label: 'Scan QR',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: AppColors.primary),
            label: 'Riwayat',
          ),
        ],
      ),
    );
  }
}

class _DashboardHomeContent extends StatelessWidget {
  const _DashboardHomeContent();

  @override
  Widget build(BuildContext context) {
    final dashboardVm = context.watch<DashboardViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warehouse, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? (authVm.isLoading ? 'Memuat profil...' : 'Pengguna Gudang'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  (user?.role ?? (authVm.isLoading ? 'Memuat...' : 'Pengguna')).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout, size: 20, color: AppColors.textSecondary),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Keluar dari Aplikasi?'),
                  content: const Text('Anda harus masuk kembali untuk mengelola gudang.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.critical),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await context.read<AuthViewModel>().signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthGate()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<DashboardViewModel>().loadDashboard(),
            context.read<AuthViewModel>().refreshProfile(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF1E40AF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sistem Manajemen Gudang',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(Icons.bolt, color: Colors.amberAccent, size: 18),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pencatatan Cepat & Tepat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildQuickActionButton(
                          context,
                          label: 'Barang Masuk',
                          icon: Icons.transit_enterexit,
                          color: AppColors.inbound,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const QrScannerView(
                                  mode: ScannerMode.inbound,
                                ),
                              ),
                            ).then((_) {
                              if (context.mounted) context.read<DashboardViewModel>().loadDashboard();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildQuickActionButton(
                          context,
                          label: 'Barang Keluar',
                          icon: Icons.call_made,
                          color: AppColors.outbound,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const QrScannerView(
                                  mode: ScannerMode.outbound,
                                ),
                              ),
                            ).then((_) {
                              if (context.mounted) context.read<DashboardViewModel>().loadDashboard();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Metrics Row
              const Text(
                'Ringkasan Stok',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Produk',
                      value: Formatters.formatNumber(dashboardVm.totalProducts),
                      icon: Icons.category_outlined,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Unit Stok',
                      value: Formatters.formatNumber(dashboardVm.totalStock),
                      icon: Icons.all_inbox_outlined,
                      color: AppColors.inbound,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Stok Menipis',
                      value: Formatters.formatNumber(dashboardVm.lowStockCount),
                      icon: Icons.warning_amber_rounded,
                      color: dashboardVm.lowStockCount > 0
                          ? AppColors.critical
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Low Stock Alert Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Peringatan Stok Menipis',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (dashboardVm.lowStockCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.critical,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${dashboardVm.lowStockCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (dashboardVm.lowStockProducts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.inbound, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Semua stok barang berada dalam batas aman.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dashboardVm.lowStockProducts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final item = dashboardVm.lowStockProducts[i];
                    return Card(
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailView(product: item),
                            ),
                          ).then((_) {
                            if (context.mounted) context.read<DashboardViewModel>().loadDashboard();
                          });
                        },
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          'SKU: ${item.sku} • Lokasi: ${item.location ?? "-"}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: StockBadge(stock: item.stock, minStock: item.minStock),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // Quick Actions Shortcuts
              const Text(
                'Aksi Cepat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (user?.isAdmin ?? false) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProductFormView(),
                            ),
                          ).then((_) {
                            if (context.mounted) context.read<DashboardViewModel>().loadDashboard();
                          });
                        },
                        icon: const Icon(Icons.add_box_outlined, size: 18),
                        label: const Text('Tambah Barang'),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const QrScannerView(mode: ScannerMode.search),
                          ),
                        ).then((_) {
                          if (context.mounted) context.read<DashboardViewModel>().loadDashboard();
                        });
                      },
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Scan Cari'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
