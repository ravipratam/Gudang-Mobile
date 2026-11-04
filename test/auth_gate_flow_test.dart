import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gudang_mobile/core/theme/app_theme.dart';
import 'package:gudang_mobile/data/models/profile_model.dart';
import 'package:gudang_mobile/data/repositories/auth_repository.dart';
import 'package:gudang_mobile/main.dart';
import 'package:gudang_mobile/ui/features/auth/views/auth_gate.dart';
import 'package:gudang_mobile/ui/features/auth/view_models/auth_view_model.dart';
import 'package:gudang_mobile/ui/features/auth/views/login_view.dart';
import 'package:gudang_mobile/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:gudang_mobile/ui/features/dashboard/views/dashboard_view.dart';
import 'package:gudang_mobile/ui/features/products/view_models/product_view_model.dart';
import 'package:gudang_mobile/ui/features/qr/view_models/scanner_view_model.dart';
import 'package:gudang_mobile/ui/features/transactions/view_models/transaction_view_model.dart';

class UnauthenticatedAuthRepo extends AuthRepository {
  @override
  bool get isAuthenticated => false;

  @override
  Future<ProfileModel?> getCurrentProfile() async => null;
}

class AuthenticatedAuthRepo extends AuthRepository {
  final ProfileModel profile;
  AuthenticatedAuthRepo(this.profile);

  @override
  bool get isAuthenticated => true;

  @override
  Future<ProfileModel?> getCurrentProfile() async => profile;
}

void main() {
  final testProfile = ProfileModel(
    id: 'user-001',
    fullName: 'Staf Lapangan',
    role: 'staff',
  );

  group('Auth Gate & Demo Removal Tests', () {
    testWidgets('LoginView has no demo buttons and fields are initially empty', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthViewModel()),
          ],
          child: const MaterialApp(
            home: LoginView(),
          ),
        ),
      );

      // Verify demo elements are removed
      expect(find.text('Akun Demo Uji Coba:'), findsNothing);
      expect(find.text('Set: Admin'), findsNothing);
      expect(find.text('Set: Staf'), findsNothing);

      // Verify email & password fields are initially empty
      final emailField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Masukkan Email'),
      );
      expect(emailField.controller?.text, isEmpty);

      final passwordField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Masukkan Password'),
      );
      expect(passwordField.controller?.text, isEmpty);
    });

    testWidgets('AuthGate shows LoginView when user is not logged in', (tester) async {
      final unauthVm = AuthViewModel(authRepository: UnauthenticatedAuthRepo());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(value: unauthVm),
            ChangeNotifierProvider(create: (_) => DashboardViewModel()),
            ChangeNotifierProvider(create: (_) => ProductViewModel()),
            ChangeNotifierProvider(create: (_) => ScannerViewModel()),
            ChangeNotifierProvider(create: (_) => TransactionViewModel()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AuthGate(),
          ),
        ),
      );

      // Settle frame callbacks and checkAuthStatus
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Must be on LoginView
      expect(find.byType(LoginView), findsOneWidget);
      expect(find.byType(DashboardView), findsNothing);
      expect(find.text('Masuk ke Gudang'), findsOneWidget);
    });

    testWidgets('AuthGate directly enters DashboardView when user was previously logged in', (tester) async {
      final authVm = AuthViewModel(authRepository: AuthenticatedAuthRepo(testProfile));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(value: authVm),
            ChangeNotifierProvider(create: (_) => DashboardViewModel()),
            ChangeNotifierProvider(create: (_) => ProductViewModel()),
            ChangeNotifierProvider(create: (_) => ScannerViewModel()),
            ChangeNotifierProvider(create: (_) => TransactionViewModel()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AuthGate(),
          ),
        ),
      );

      // Settle frame callbacks, checkAuthStatus, and loadDashboard
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Must directly be on DashboardView
      expect(find.byType(DashboardView), findsOneWidget);
      expect(find.byType(LoginView), findsNothing);
      expect(find.text('Staf Lapangan'), findsOneWidget);
    });

    testWidgets('Re-opening app with active session stays on DashboardView without jitter or infinite unmount', (tester) async {
      final authVm = AuthViewModel(authRepository: AuthenticatedAuthRepo(testProfile));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(value: authVm),
            ChangeNotifierProvider(create: (_) => DashboardViewModel()),
            ChangeNotifierProvider(create: (_) => ProductViewModel()),
            ChangeNotifierProvider(create: (_) => ScannerViewModel()),
            ChangeNotifierProvider(create: (_) => TransactionViewModel()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AuthGate(),
          ),
        ),
      );

      // Settle initial frame & checkAuthStatus
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(DashboardView), findsOneWidget);
      expect(authVm.isCheckingAuth, isFalse);

      // Pump multiple subsequent frames simulating runtime
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Verify DashboardView is permanently mounted and isCheckingAuth remains false
      expect(find.byType(DashboardView), findsOneWidget);
      expect(authVm.isCheckingAuth, isFalse);
    });
  });
}
