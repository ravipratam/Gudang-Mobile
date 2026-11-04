import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gudang_mobile/data/repositories/auth_repository.dart';
import 'package:gudang_mobile/ui/features/auth/view_models/auth_view_model.dart';
import 'package:gudang_mobile/ui/features/auth/views/login_view.dart';
import 'package:gudang_mobile/ui/features/auth/views/register_view.dart';

void main() {
  group('Auth Registration Tests', () {
    test('AuthRepository signUp creates user in demo mode', () async {
      final repo = AuthRepository();
      final user = await repo.signUp(
        email: 'userbaru@gudang.com',
        password: 'password123',
        fullName: 'Staf Baru Gudang',
        role: 'staff',
      );

      expect(user.fullName, 'Staf Baru Gudang');
      expect(user.role, 'staff');
      expect(repo.isAuthenticated, isTrue);
    });

    test('AuthViewModel signUp updates state and authentication', () async {
      final vm = AuthViewModel();
      final success = await vm.signUp(
        email: 'adminbaru@gudang.com',
        password: 'securepassword',
        fullName: 'Manager Gudang',
        role: 'admin',
      );

      expect(success, isTrue);
      expect(vm.profile?.fullName, 'Manager Gudang');
      expect(vm.profile?.isAdmin, isTrue);
      expect(vm.isAuthenticated, isTrue);
    });

    testWidgets('LoginView shows "Daftar Sekarang" and navigates to RegisterView', (tester) async {
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

      // Verify "Belum punya akun?" and "Daftar Sekarang" are present
      expect(find.text('Belum punya akun? '), findsOneWidget);
      expect(find.text('Daftar Sekarang'), findsOneWidget);

      // Tap on "Daftar Sekarang"
      await tester.tap(find.text('Daftar Sekarang'));
      await tester.pumpAndSettle();

      // Verify RegisterView is displayed
      expect(find.byType(RegisterView), findsOneWidget);
      expect(find.text('Buat Akun Baru'), findsOneWidget);
      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('Peran / Posisi di Gudang'), findsOneWidget);
    });

    testWidgets('RegisterView validates empty fields properly', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthViewModel()),
          ],
          child: const MaterialApp(
            home: RegisterView(),
          ),
        ),
      );

      // Tap "Daftar Sekarang" button without filling form
      final submitButton = find.widgetWithText(ElevatedButton, 'Daftar Sekarang');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify validation errors appear
      expect(find.text('Nama lengkap wajib diisi'), findsOneWidget);
      expect(find.text('Email wajib diisi'), findsOneWidget);
      expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    });
  });
}
