import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gudang_mobile/data/models/profile_model.dart';
import 'package:gudang_mobile/data/repositories/auth_repository.dart';
import 'package:gudang_mobile/data/services/supabase_service.dart';
import 'package:gudang_mobile/ui/core/profile_avatar.dart';
import 'package:gudang_mobile/ui/features/auth/view_models/auth_view_model.dart';
import 'package:gudang_mobile/ui/features/dashboard/view_models/dashboard_view_model.dart';
import 'package:gudang_mobile/ui/features/dashboard/views/dashboard_view.dart';
import 'package:gudang_mobile/ui/features/products/view_models/product_view_model.dart';
import 'package:gudang_mobile/ui/features/qr/view_models/scanner_view_model.dart';
import 'package:gudang_mobile/ui/features/transactions/view_models/transaction_view_model.dart';
import 'package:gudang_mobile/ui/features/profile/views/change_password_dialog.dart';
import 'package:gudang_mobile/ui/features/profile/views/edit_profile_view.dart';
import 'package:gudang_mobile/ui/features/profile/views/profile_view.dart';

class MockProfileAuthRepo extends AuthRepository {
  ProfileModel current;
  MockProfileAuthRepo(this.current);

  @override
  bool get isAuthenticated => true;

  @override
  Future<ProfileModel?> getCurrentProfile() async => current;

  @override
  Future<ProfileModel> signIn({required String email, required String password}) async => current;

  @override
  Future<ProfileModel> updateProfileName(String newFullName) async {
    current = current.copyWith(fullName: newFullName);
    return current;
  }

  @override
  Future<void> updateEmail({required String newEmail, String? currentPassword}) async {
    current = current.copyWith(email: newEmail);
  }

  @override
  Future<void> updatePassword({required String currentPassword, required String newPassword}) async {}
}

void main() {
  group('ProfileModel Unit Tests', () {
    test('toJson and fromJson serializes email and avatarUrl correctly', () {
      final model = ProfileModel(
        id: 'test-user-1',
        fullName: 'Ahmad Dani',
        role: 'admin',
        email: 'ahmad@gudang.com',
        avatarUrl: 'https://example.com/avatar.jpg',
      );

      final json = model.toJson();
      expect(json['id'], 'test-user-1');
      expect(json['full_name'], 'Ahmad Dani');
      expect(json['role'], 'admin');
      expect(json['email'], 'ahmad@gudang.com');
      expect(json['avatar_url'], 'https://example.com/avatar.jpg');

      final reconstructed = ProfileModel.fromJson(json);
      expect(reconstructed.id, model.id);
      expect(reconstructed.fullName, model.fullName);
      expect(reconstructed.role, model.role);
      expect(reconstructed.email, model.email);
      expect(reconstructed.avatarUrl, model.avatarUrl);
      expect(reconstructed, equals(model));
    });

    test('copyWith updates properties or clears avatarUrl properly', () {
      final model = ProfileModel(
        id: 'test-1',
        fullName: 'Initial Name',
        role: 'staff',
        email: 'initial@gudang.com',
        avatarUrl: 'https://example.com/img.png',
      );

      final updated = model.copyWith(
        fullName: 'Updated Name',
        email: 'updated@gudang.com',
      );
      expect(updated.fullName, 'Updated Name');
      expect(updated.email, 'updated@gudang.com');
      expect(updated.avatarUrl, 'https://example.com/img.png');

      final cleared = updated.copyWith(clearAvatar: true);
      expect(cleared.avatarUrl, isNull);
    });
  });

  group('AuthRepository & SupabaseService Profile Integration Tests', () {
    late SupabaseService service;
    late AuthRepository repo;

    setUp(() async {
      service = SupabaseService();
      repo = AuthRepository(service: service);
      await repo.signIn(email: 'admin@gudang.com', password: 'password123');
    });

    test('Can edit full name', () async {
      final updated = await repo.updateProfileName('Budi Administrator');
      expect(updated.fullName, 'Budi Administrator');

      final current = await repo.getCurrentProfile();
      expect(current?.fullName, 'Budi Administrator');
    });

    test('Validates empty and short names', () async {
      expect(
        () => repo.updateProfileName(''),
        throwsA(isA<Exception>().having((e) => e.toString(), 'msg', contains('tidak boleh kosong'))),
      );
      expect(
        () => repo.updateProfileName('A'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'msg', contains('minimal terdiri dari 2 karakter'))),
      );
    });

    test('Can upload and update profile avatar', () async {
      final sampleBytes = utf8.encode('test-image-content');
      final avatarDataUrl = await repo.uploadAvatar(
        bytes: sampleBytes,
        fileName: 'avatar.png',
        mimeType: 'image/png',
      );

      expect(avatarDataUrl.startsWith('data:image/png;base64,'), isTrue);

      final updatedProfile = await repo.updateAvatarUrl(avatarDataUrl);
      expect(updatedProfile.avatarUrl, avatarDataUrl);

      final removedProfile = await repo.updateAvatarUrl(null, clearAvatar: true);
      expect(removedProfile.avatarUrl, isNull);
    });

    test('Can change password and verify correct old password', () async {
      await repo.updatePassword(
        currentPassword: 'password123',
        newPassword: 'newpassword456',
      );

      final user = await repo.signIn(email: 'admin@gudang.com', password: 'newpassword456');
      expect(user.email, 'admin@gudang.com');

      expect(
        () => repo.updatePassword(
          currentPassword: 'wrongpassword',
          newPassword: 'anotherpassword',
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'msg', contains('Password saat ini salah'))),
      );

      // Restore password
      await repo.updatePassword(
        currentPassword: 'newpassword456',
        newPassword: 'password123',
      );
    });

    test('Can edit email', () async {
      await repo.updateEmail(
        newEmail: 'admin_baru@gudang.com',
        currentPassword: 'password123',
      );

      final profile = await repo.getCurrentProfile();
      expect(profile?.email, 'admin_baru@gudang.com');

      // Restore back for other tests
      await repo.updateEmail(
        newEmail: 'admin@gudang.com',
        currentPassword: 'password123',
      );
    });
  });

  group('Profile Widget Tests', () {
    final testStaffProfile = ProfileModel(
      id: 'mock-user-456',
      fullName: 'Siti Rahma',
      role: 'staff',
      email: 'staff@gudang.com',
    );

    final testAdminProfile = ProfileModel(
      id: 'mock-user-123',
      fullName: 'Budi Santoso',
      role: 'admin',
      email: 'admin@gudang.com',
    );

    testWidgets('ProfileAvatar renders initials and badge correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileAvatar(
              name: 'Siti Rahma',
              radius: 30,
              showEditBadge: true,
            ),
          ),
        ),
      );

      expect(find.text('SR'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('ProfileView renders profile information and action buttons', (tester) async {
      final authVm = AuthViewModel(authRepository: MockProfileAuthRepo(testStaffProfile));
      await authVm.checkAuthStatus();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authVm),
          ],
          child: const MaterialApp(
            home: ProfileView(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Profil Akun'), findsOneWidget);
      expect(find.text('Siti Rahma'), findsOneWidget);
      expect(find.text('staff@gudang.com'), findsOneWidget);
      expect(find.text('STAF GUDANG'), findsOneWidget);
      expect(find.text('Edit Profil & Foto'), findsOneWidget);
      expect(find.text('Ubah Password'), findsOneWidget);
      expect(find.text('Keluar dari Akun'), findsOneWidget);
    });

    testWidgets('EditProfileView renders fields and validates properly', (tester) async {
      final authVm = AuthViewModel(authRepository: MockProfileAuthRepo(testStaffProfile));
      await authVm.checkAuthStatus();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authVm),
          ],
          child: const MaterialApp(
            home: EditProfileView(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Edit Profil'), findsOneWidget);
      expect(find.text('Data Pribadi Akun'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);
      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('Alamat Email'), findsOneWidget);
    });

    testWidgets('ChangePasswordDialog validates input fields', (tester) async {
      final authVm = AuthViewModel(authRepository: MockProfileAuthRepo(testStaffProfile));
      await authVm.checkAuthStatus();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authVm),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ChangePasswordDialog(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Ubah Password'), findsOneWidget);
      expect(find.text('Password Saat Ini'), findsOneWidget);
      expect(find.text('Password Baru'), findsOneWidget);
      expect(find.text('Konfirmasi Password Baru'), findsOneWidget);

      // Tap Simpan when empty
      await tester.tap(find.text('Simpan'));
      await tester.pump();

      expect(find.text('Password saat ini wajib diisi.'), findsOneWidget);
      expect(find.text('Password baru wajib diisi.'), findsOneWidget);
    });

    testWidgets('DashboardView bottom navigation includes Profil tab', (tester) async {
      final authVm = AuthViewModel(authRepository: MockProfileAuthRepo(testAdminProfile));
      await authVm.checkAuthStatus();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authVm),
            ChangeNotifierProvider(create: (_) => DashboardViewModel()),
            ChangeNotifierProvider(create: (_) => ProductViewModel()),
            ChangeNotifierProvider(create: (_) => ScannerViewModel()),
            ChangeNotifierProvider(create: (_) => TransactionViewModel()),
          ],
          child: const MaterialApp(
            home: DashboardView(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Find Profil destination
      expect(find.text('Profil'), findsOneWidget);

      // Tap on Profil tab
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      expect(find.text('Profil Akun'), findsOneWidget);
      expect(find.text('Edit Profil & Foto'), findsOneWidget);
      expect(find.text('Ubah Password'), findsOneWidget);
    });
  });
}
