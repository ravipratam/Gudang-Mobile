import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gudang_mobile/data/repositories/auth_repository.dart';
import 'package:gudang_mobile/ui/features/auth/view_models/auth_view_model.dart';
import 'package:gudang_mobile/ui/features/auth/views/login_view.dart';

void main() {
  group('Auth Error Notification Tests', () {
    test('Non-existent account triggers specific error message in AuthRepository', () async {
      final repo = AuthRepository();

      expect(
        () => repo.signIn(email: 'tidakada@gudang.com', password: 'password123'),
        throwsA(predicate((e) =>
            e is Exception &&
            e.toString().contains('Akun belum terdaftar'))),
      );
    });

    test('Wrong password triggers specific error message in AuthRepository', () async {
      final repo = AuthRepository();

      expect(
        () => repo.signIn(email: 'admin@gudang.com', password: 'password_salah_123'),
        throwsA(predicate((e) =>
            e is Exception &&
            e.toString().contains('Password salah'))),
      );
    });

    test('Correct password succeeds for existing mock user', () async {
      final repo = AuthRepository();
      final user = await repo.signIn(email: 'admin@gudang.com', password: 'password123');

      expect(user.fullName, 'Budi Santoso');
      expect(user.role, 'admin');
    });

    testWidgets('LoginView displays error notification when account does not exist', (tester) async {
      final authVm = AuthViewModel(authRepository: AuthRepository());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(value: authVm),
          ],
          child: const MaterialApp(
            home: LoginView(),
          ),
        ),
      );

      // Enter unregistered email & password
      final emailField = find.widgetWithText(TextFormField, 'Masukkan Email');
      final passwordField = find.widgetWithText(TextFormField, 'Masukkan Password');
      final submitButton = find.widgetWithText(ElevatedButton, 'Masuk ke Gudang');

      await tester.enterText(emailField, 'akunbelumada@gudang.com');
      await tester.enterText(passwordField, 'password123');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);

      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Verify inline error banner is visible
      expect(find.text('Akun Belum Terdaftar'), findsOneWidget);
      expect(find.textContaining('Akun belum terdaftar'), findsWidgets);
      expect(find.text('Daftar akun baru sekarang →'), findsOneWidget);

      // Verify SnackBar notification is shown
      expect(find.text('Akun Tidak Ditemukan'), findsOneWidget);
      expect(find.text('DAFTAR'), findsOneWidget);
    });

    testWidgets('LoginView displays error notification when password is wrong', (tester) async {
      final authVm = AuthViewModel(authRepository: AuthRepository());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(value: authVm),
          ],
          child: const MaterialApp(
            home: LoginView(),
          ),
        ),
      );

      // Enter valid email with wrong password
      final emailField = find.widgetWithText(TextFormField, 'Masukkan Email');
      final passwordField = find.widgetWithText(TextFormField, 'Masukkan Password');
      final submitButton = find.widgetWithText(ElevatedButton, 'Masuk ke Gudang');

      await tester.enterText(emailField, 'admin@gudang.com');
      await tester.enterText(passwordField, 'wrong_pass_123');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);

      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Verify inline error banner is visible
      expect(find.text('Password Salah'), findsWidgets);
      expect(find.textContaining('Password salah. Silakan periksa kembali'), findsWidgets);
      expect(find.text('Lupa password? Atur ulang di sini →'), findsOneWidget);

      // Verify SnackBar notification is shown
      expect(find.text('LUPA?'), findsOneWidget);
    });

    testWidgets('Typing in fields clears the error notification', (tester) async {
      final authVm = AuthViewModel(authRepository: AuthRepository());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthViewModel>.value(value: authVm),
          ],
          child: const MaterialApp(
            home: LoginView(),
          ),
        ),
      );

      final emailField = find.widgetWithText(TextFormField, 'Masukkan Email');
      final passwordField = find.widgetWithText(TextFormField, 'Masukkan Password');
      final submitButton = find.widgetWithText(ElevatedButton, 'Masuk ke Gudang');

      await tester.enterText(emailField, 'admin@gudang.com');
      await tester.enterText(passwordField, 'salah123');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);

      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('Password Salah'), findsWidgets);

      // Type in password field to correct it
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Banner should be cleared
      expect(find.text('Lupa password? Atur ulang di sini →'), findsNothing);
    });
  });
}
