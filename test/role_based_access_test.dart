import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gudang_mobile/core/theme/app_theme.dart';
import 'package:gudang_mobile/data/models/product_model.dart';
import 'package:gudang_mobile/data/models/profile_model.dart';
import 'package:gudang_mobile/data/repositories/auth_repository.dart';
import 'package:gudang_mobile/ui/features/auth/view_models/auth_view_model.dart';
import 'package:gudang_mobile/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:gudang_mobile/ui/features/dashboard/views/dashboard_view.dart';
import 'package:gudang_mobile/ui/features/products/view_models/product_view_model.dart';
import 'package:gudang_mobile/ui/features/products/views/product_list_view.dart';
import 'package:gudang_mobile/ui/features/products/views/product_form_view.dart';
import 'package:gudang_mobile/ui/features/products/views/product_detail_view.dart';
import 'package:gudang_mobile/ui/features/qr/view_models/scanner_view_model.dart';
import 'package:gudang_mobile/ui/features/transactions/view_models/transaction_view_model.dart';

class MockAuthRepository extends AuthRepository {
  final ProfileModel mockProfile;

  MockAuthRepository(this.mockProfile);

  @override
  bool get isAuthenticated => true;

  @override
  Future<ProfileModel?> getCurrentProfile() async => mockProfile;

  @override
  Future<ProfileModel> signIn({required String email, required String password}) async => mockProfile;
}

void main() {
  final adminProfile = ProfileModel(
    id: 'admin-id',
    fullName: 'Admin Gudang',
    role: 'admin',
  );

  final staffProfile = ProfileModel(
    id: 'staff-id',
    fullName: 'Staf Gudang',
    role: 'staff',
  );

  group('Role-Based Access Control (Admin vs Staff)', () {
    test('Verify isAdmin returns true for admin and false for staff', () async {
      final adminVm = AuthViewModel(authRepository: MockAuthRepository(adminProfile));
      await adminVm.checkAuthStatus();
      expect(adminVm.profile?.role, 'admin');
      expect(adminVm.isAdmin, isTrue);

      final staffVm = AuthViewModel(authRepository: MockAuthRepository(staffProfile));
      await staffVm.checkAuthStatus();
      expect(staffVm.profile?.role, 'staff');
      expect(staffVm.isAdmin, isFalse);
    });

    testWidgets('Dashboard: Admin sees "Tambah Barang" button', (tester) async {
      final adminVm = AuthViewModel(authRepository: MockAuthRepository(adminProfile));
      await adminVm.checkAuthStatus();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(value: adminVm),
            ChangeNotifierProvider(create: (_) => DashboardViewModel()),
            ChangeNotifierProvider(create: (_) => ProductViewModel()),
            ChangeNotifierProvider(create: (_) => ScannerViewModel()),
            ChangeNotifierProvider(create: (_) => TransactionViewModel()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DashboardView(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Role badge says ADMIN
      expect(find.text('ADMIN'), findsOneWidget);

      // "Tambah Barang" is visible for Admin
      expect(find.widgetWithText(OutlinedButton, 'Tambah Barang'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Scan Cari'), findsOneWidget);
    });

    testWidgets('Dashboard: Staff DOES NOT see "Tambah Barang" button', (tester) async {
      final staffVm = AuthViewModel(authRepository: MockAuthRepository(staffProfile));
      await staffVm.checkAuthStatus();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(value: staffVm),
            ChangeNotifierProvider(create: (_) => DashboardViewModel()),
            ChangeNotifierProvider(create: (_) => ProductViewModel()),
            ChangeNotifierProvider(create: (_) => ScannerViewModel()),
            ChangeNotifierProvider(create: (_) => TransactionViewModel()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DashboardView(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Role badge says STAFF
      expect(find.text('STAFF'), findsOneWidget);

      // "Tambah Barang" is NOT visible for Staff
      expect(find.widgetWithText(OutlinedButton, 'Tambah Barang'), findsNothing);

      // Staff still sees "Scan Cari"
      expect(find.widgetWithText(ElevatedButton, 'Scan Cari'), findsOneWidget);
    });

    testWidgets('ProductListView: Admin sees "Tambah Barang" action button in AppBar', (tester) async {
      final adminVm = AuthViewModel(authRepository: MockAuthRepository(adminProfile));
      await adminVm.checkAuthStatus();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(value: adminVm),
            ChangeNotifierProvider(create: (_) => ProductViewModel()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProductListView(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Admin has tooltip "Tambah Barang" in AppBar
      expect(find.byTooltip('Tambah Barang'), findsOneWidget);
    });

    testWidgets('ProductListView: Staff DOES NOT see "Tambah Barang" action button in AppBar', (tester) async {
      final staffVm = AuthViewModel(authRepository: MockAuthRepository(staffProfile));
      await staffVm.checkAuthStatus();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(value: staffVm),
            ChangeNotifierProvider(create: (_) => ProductViewModel()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProductListView(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Staff does NOT have "Tambah Barang" in AppBar
      expect(find.byTooltip('Tambah Barang'), findsNothing);
    });

    testWidgets('ProductFormView: Staff is prevented from adding new product', (tester) async {
      final staffVm = AuthViewModel(authRepository: MockAuthRepository(staffProfile));
      await staffVm.checkAuthStatus();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(value: staffVm),
            ChangeNotifierProvider(create: (_) => ProductViewModel()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProductFormView(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Access restriction screen is shown
      expect(find.text('Fitur Tambah Barang Dibatasi'), findsOneWidget);
      expect(
        find.text('Hanya pengguna dengan akun Admin yang memiliki izin untuk menambah barang baru ke gudang.'),
        findsOneWidget,
      );
      expect(find.text('Tambah ke Gudang'), findsNothing);
    });

    testWidgets('ProductFormView: Admin can access form and see submit button', (tester) async {
      final adminVm = AuthViewModel(authRepository: MockAuthRepository(adminProfile));
      await adminVm.checkAuthStatus();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(value: adminVm),
            ChangeNotifierProvider(create: (_) => ProductViewModel()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProductFormView(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Admin has full access to the form
      expect(find.text('Tambah Barang Baru'), findsOneWidget);
      expect(find.text('Tambah ke Gudang'), findsOneWidget);
      expect(find.text('Fitur Tambah Barang Dibatasi'), findsNothing);
    });

    testWidgets('ProductDetailView: Admin sees "Ubah Data" and "Hapus Barang" action buttons in AppBar', (tester) async {
      final adminVm = AuthViewModel(authRepository: MockAuthRepository(adminProfile));
      await adminVm.checkAuthStatus();

      final sampleProduct = ProductModel(
        id: 'prod-001',
        sku: 'TST-001',
        name: 'Barang Uji Coba',
        stock: 15,
        minStock: 5,
        location: 'Rak A-1',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(value: adminVm),
            ChangeNotifierProvider(create: (_) => ProductViewModel()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: ProductDetailView(product: sampleProduct),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Admin sees both "Ubah Data" and "Hapus Barang" buttons
      expect(find.byTooltip('Ubah Data'), findsOneWidget);
      expect(find.byTooltip('Hapus Barang'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('ProductDetailView: Staff DOES NOT see "Ubah Data" or "Hapus Barang" action buttons in AppBar', (tester) async {
      final staffVm = AuthViewModel(authRepository: MockAuthRepository(staffProfile));
      await staffVm.checkAuthStatus();

      final sampleProduct = ProductModel(
        id: 'prod-001',
        sku: 'TST-001',
        name: 'Barang Uji Coba',
        stock: 15,
        minStock: 5,
        location: 'Rak A-1',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(value: staffVm),
            ChangeNotifierProvider(create: (_) => ProductViewModel()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: ProductDetailView(product: sampleProduct),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Staff does NOT see "Ubah Data" or "Hapus Barang" buttons
      expect(find.byTooltip('Ubah Data'), findsNothing);
      expect(find.byTooltip('Hapus Barang'), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);

      // Staff still sees stock action buttons ('Barang Masuk (+)' and 'Barang Keluar (-)')
      expect(find.text('Barang Masuk (+)'), findsOneWidget);
      expect(find.text('Barang Keluar (-)'), findsOneWidget);
    });
  });
}
