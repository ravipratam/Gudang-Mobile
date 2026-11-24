import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../services/supabase_service.dart';

class AuthRepository {
  final SupabaseService _service;

  AuthRepository({SupabaseService? service}) : _service = service ?? SupabaseService();

  User? get currentAuthUser => _service.client?.auth.currentUser;

  bool get isAuthenticated {
    if (_service.isLive) {
      return _service.client?.auth.currentUser != null;
    }
    return _service.mockCurrentUser != null;
  }

  Future<ProfileModel?> getCurrentProfile() async {
    if (!_service.isLive) {
      return _service.mockCurrentUser;
    }

    final user = _service.client?.auth.currentUser;
    if (user == null) return null;

    final metaRole = (user.userMetadata?['role'] as String?)?.trim().toLowerCase();
    final metaName = (user.userMetadata?['full_name'] as String?)?.trim();
    final metaAvatar = (user.userMetadata?['avatar_url'] as String?)?.trim();
    final userEmail = user.email;

    try {
      final data = await _service.client!
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 4));

      if (data != null) {
        var profile = ProfileModel.fromJson(
          data,
          fallbackEmail: userEmail,
          fallbackAvatarUrl: metaAvatar,
        );
        // If database profile has role 'staff' but metadata has 'admin' (e.g. database trigger defaulted to staff),
        // sync database profile with metadata role.
        if (metaRole != null && metaRole.isNotEmpty && profile.role.toLowerCase() != metaRole) {
          try {
            await _service.client!
                .from('profiles')
                .update({'role': metaRole})
                .eq('id', user.id);
            profile = profile.copyWith(role: metaRole);
          } catch (_) {
            profile = profile.copyWith(role: metaRole);
          }
        }
        return profile;
      } else {
        // Fallback create profile if missing in profiles table
        final targetRole = (metaRole != null && metaRole.isNotEmpty) ? metaRole : 'staff';
        final targetName = (metaName != null && metaName.isNotEmpty)
            ? metaName
            : (user.email?.split('@').first ?? 'Pengguna Gudang');

        final newProfile = ProfileModel(
          id: user.id,
          fullName: targetName,
          role: targetRole,
          email: userEmail,
          avatarUrl: metaAvatar,
        );
        try {
          await _service.client!.from('profiles').insert(newProfile.toJson());
        } catch (_) {}
        return newProfile;
      }
    } catch (_) {
      final targetRole = (metaRole != null && metaRole.isNotEmpty) ? metaRole : 'staff';
      final targetName = (metaName != null && metaName.isNotEmpty)
          ? metaName
          : (user.email?.split('@').first ?? 'Pengguna Gudang');

      return ProfileModel(
        id: user.id,
        fullName: targetName,
        role: targetRole,
        email: userEmail,
        avatarUrl: metaAvatar,
      );
    }
  }

  Future<ProfileModel> signIn({required String email, required String password}) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      throw Exception('Email dan password tidak boleh kosong.');
    }

    if (!_service.isLive) {
      // Offline mock login
      await Future.delayed(const Duration(milliseconds: 600));

      final existingMock = _service.getMockUser(cleanEmail);
      if (existingMock == null) {
        throw Exception('Akun belum terdaftar. Silakan periksa kembali email Anda atau daftar akun baru.');
      }

      final expectedPassword = _service.getMockPassword(cleanEmail);
      final isValidAdmin = cleanEmail == 'admin@gudang.com' &&
          (cleanPassword == expectedPassword || cleanPassword == 'admin123' || cleanPassword == 'password123');
      final isValidStaff = cleanEmail == 'staff@gudang.com' &&
          (cleanPassword == expectedPassword || cleanPassword == 'staff123' || cleanPassword == 'password123');
      final isValidCustom = expectedPassword != null && cleanPassword == expectedPassword;

      if (!isValidAdmin && !isValidStaff && !isValidCustom) {
        throw Exception('Password salah. Silakan periksa kembali password Anda.');
      }

      await _service.setMockCurrentUser(existingMock);
      return existingMock;
    }

    try {
      final response = await _service.client!.auth.signInWithPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      if (response.user == null) {
        throw Exception('Gagal masuk ke akun.');
      }

      await _service.saveKnownRegisteredEmail(cleanEmail);

      final profile = await getCurrentProfile();
      final metaRole = (response.user!.userMetadata?['role'] as String?)?.trim().toLowerCase();
      final metaName = (response.user!.userMetadata?['full_name'] as String?)?.trim();

      return profile ??
          ProfileModel(
            id: response.user!.id,
            fullName: (metaName != null && metaName.isNotEmpty)
                ? metaName
                : (response.user!.email?.split('@').first ?? 'Pengguna Gudang'),
            role: (metaRole != null && metaRole.isNotEmpty) ? metaRole : 'staff',
            email: response.user!.email,
            avatarUrl: (response.user!.userMetadata?['avatar_url'] as String?)?.trim(),
          );
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      final code = (e.code ?? '').toLowerCase();

      bool? userExists;
      try {
        final rpcRes = await _service.client!.rpc('check_user_exists', params: {'p_email': cleanEmail});
        if (rpcRes is bool) userExists = rpcRes;
      } catch (_) {
        if (_service.isKnownRegisteredEmail(cleanEmail)) {
          userExists = true;
        }
      }

      if (userExists == false || msg.contains('user not found') || code == 'user_not_found') {
        throw Exception('Akun belum terdaftar. Silakan periksa kembali email Anda atau daftar akun baru.');
      } else if (userExists == true) {
        throw Exception('Password salah. Silakan periksa kembali password Anda.');
      } else if (msg.contains('invalid login credentials') || code == 'invalid_credentials' || code == 'invalid_grant') {
        throw Exception('Password salah atau akun belum terdaftar. Silakan periksa kembali data login Anda.');
      } else if (msg.contains('email not confirmed')) {
        throw Exception('Email belum dikonfirmasi. Silakan periksa inbox email Anda.');
      } else if (msg.contains('rate limit') || msg.contains('too many requests')) {
        throw Exception('Terlalu banyak percobaan masuk. Silakan tunggu beberapa saat.');
      } else {
        throw Exception('Gagal masuk: ${e.message}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat masuk. Periksa koneksi internet Anda.');
    }
  }

  Future<ProfileModel> signUp({
    required String email,
    required String password,
    required String fullName,
    String role = 'staff',
  }) async {
    final cleanRole = role.trim().toLowerCase();
    final cleanFullName = fullName.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty || password.trim().isEmpty || cleanFullName.isEmpty) {
      throw Exception('Semua bidang wajib diisi.');
    }

    if (!_service.isLive) {
      // Offline mock registration
      await Future.delayed(const Duration(milliseconds: 600));
      if (_service.getMockUser(cleanEmail) != null) {
        throw Exception('Email sudah terdaftar. Silakan gunakan email lain atau masuk ke akun Anda.');
      }
      final mockUser = ProfileModel(
        id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
        fullName: cleanFullName,
        role: cleanRole,
        createdAt: DateTime.now(),
      );
      await _service.registerMockUser(cleanEmail, mockUser, password: password.trim());
      return mockUser;
    }

    try {
      final response = await _service.client!.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {
          'full_name': cleanFullName,
          'role': cleanRole,
        },
      );

      if (response.user == null) {
        throw Exception('Gagal mendaftar akun baru.');
      }

      await _service.saveKnownRegisteredEmail(cleanEmail);

      // Attempt to upsert to profiles table in case database trigger hasn't fired yet
      if (response.session != null) {
        try {
          await _service.client!.from('profiles').upsert({
            'id': response.user!.id,
            'full_name': cleanFullName,
            'role': cleanRole,
          });
        } catch (_) {}
      } else {
        // If session is null, attempt immediate sign-in (if email confirmation is turned off)
        try {
          final loginRes = await _service.client!.auth.signInWithPassword(
            email: cleanEmail,
            password: password,
          );
          if (loginRes.session != null) {
            await _service.client!.from('profiles').upsert({
              'id': response.user!.id,
              'full_name': cleanFullName,
              'role': cleanRole,
            });
          }
        } catch (_) {}
      }

      final profile = await getCurrentProfile();
      return profile ??
          ProfileModel(
            id: response.user!.id,
            fullName: cleanFullName,
            role: cleanRole,
            email: cleanEmail,
          );
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      final code = (e.code ?? '').toLowerCase();
      if (msg.contains('already registered') || code == 'user_already_exists') {
        throw Exception('Email sudah terdaftar. Silakan gunakan email lain atau masuk ke akun Anda.');
      } else {
        throw Exception('Pendaftaran gagal: ${e.message}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat pendaftaran.');
    }
  }

  Future<void> signOut() async {
    if (!_service.isLive) {
      await _service.setMockCurrentUser(null);
      return;
    }
    await _service.client?.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    if (!_service.isLive) {
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }
    await _service.client?.auth.resetPasswordForEmail(email.trim());
  }

  Future<ProfileModel> updateProfileName(String newFullName) async {
    final cleanName = newFullName.trim();
    if (cleanName.isEmpty) {
      throw Exception('Nama lengkap tidak boleh kosong.');
    }
    if (cleanName.length < 2) {
      throw Exception('Nama lengkap minimal terdiri dari 2 karakter.');
    }

    if (!_service.isLive) {
      final current = _service.mockCurrentUser;
      if (current == null) {
        throw Exception('Sesi tidak ditemukan.');
      }
      return await _service.updateMockProfile(
        id: current.id,
        fullName: cleanName,
      );
    }

    final user = _service.client?.auth.currentUser;
    if (user == null) {
      throw Exception('Sesi telah berakhir. Silakan masuk kembali.');
    }

    await _service.client!.auth.updateUser(
      UserAttributes(
        data: {'full_name': cleanName},
      ),
    );

    try {
      await _service.client!.from('profiles').update({
        'full_name': cleanName,
      }).eq('id', user.id);
    } catch (_) {}

    final updated = await getCurrentProfile();
    return updated ??
        ProfileModel(
          id: user.id,
          fullName: cleanName,
          role: (user.userMetadata?['role'] as String?) ?? 'staff',
          email: user.email,
          avatarUrl: user.userMetadata?['avatar_url'] as String?,
        );
  }

  Future<ProfileModel> updateAvatarUrl(String? avatarUrl, {bool clearAvatar = false}) async {
    if (!_service.isLive) {
      final current = _service.mockCurrentUser;
      if (current == null) {
        throw Exception('Sesi tidak ditemukan.');
      }
      return await _service.updateMockProfile(
        id: current.id,
        avatarUrl: avatarUrl,
        clearAvatar: clearAvatar,
      );
    }

    final user = _service.client?.auth.currentUser;
    if (user == null) {
      throw Exception('Sesi telah berakhir. Silakan masuk kembali.');
    }

    await _service.client!.auth.updateUser(
      UserAttributes(
        data: {'avatar_url': clearAvatar ? null : avatarUrl},
      ),
    );

    try {
      await _service.client!.from('profiles').update({
        'avatar_url': clearAvatar ? null : avatarUrl,
      }).eq('id', user.id);
    } catch (_) {}

    final updated = await getCurrentProfile();
    return updated ??
        ProfileModel(
          id: user.id,
          fullName: (user.userMetadata?['full_name'] as String?) ?? 'Pengguna Gudang',
          role: (user.userMetadata?['role'] as String?) ?? 'staff',
          email: user.email,
          avatarUrl: clearAvatar ? null : avatarUrl,
        );
  }

  Future<String> uploadAvatar({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('File foto tidak valid atau kosong.');
    }

    if (!_service.isLive) {
      return 'data:$mimeType;base64,${base64Encode(bytes)}';
    }

    final user = _service.client?.auth.currentUser;
    if (user == null) {
      throw Exception('Sesi telah berakhir. Silakan masuk kembali.');
    }

    final ext = fileName.contains('.') ? fileName.split('.').last : 'jpg';
    final storagePath = '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

    try {
      await _service.client!.storage.from('avatars').uploadBinary(
        storagePath,
        Uint8List.fromList(bytes),
        fileOptions: FileOptions(
          contentType: mimeType,
          upsert: true,
        ),
      );
      final publicUrl = _service.client!.storage.from('avatars').getPublicUrl(storagePath);
      return publicUrl;
    } catch (_) {
      // Fallback gracefully to base64 data URI if bucket doesn't exist
      return 'data:$mimeType;base64,${base64Encode(bytes)}';
    }
  }

  Future<void> updateEmail({
    required String newEmail,
    String? currentPassword,
  }) async {
    final cleanEmail = newEmail.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      throw Exception('Email baru tidak boleh kosong.');
    }

    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(cleanEmail)) {
      throw Exception('Format email tidak valid. Masukkan email yang benar.');
    }

    if (!_service.isLive) {
      final current = _service.mockCurrentUser;
      if (current == null) {
        throw Exception('Sesi tidak ditemukan.');
      }
      final currentEmail = current.email ?? 'admin@gudang.com';
      if (currentEmail.toLowerCase() == cleanEmail) {
        throw Exception('Email baru tidak boleh sama dengan email saat ini.');
      }

      if (currentPassword != null && currentPassword.isNotEmpty) {
        final expectedPwd = _service.getMockPassword(currentEmail);
        if (expectedPwd != null && currentPassword.trim() != expectedPwd) {
          throw Exception('Password konfirmasi salah.');
        }
      }

      await _service.updateMockEmail(
        oldEmail: currentEmail,
        newEmail: cleanEmail,
      );
      return;
    }

    final user = _service.client?.auth.currentUser;
    if (user == null) {
      throw Exception('Sesi telah berakhir. Silakan masuk kembali.');
    }

    if (user.email?.toLowerCase() == cleanEmail) {
      throw Exception('Email baru tidak boleh sama dengan email saat ini.');
    }

    // If currentPassword is provided, verify it first
    if (currentPassword != null && currentPassword.isNotEmpty && user.email != null) {
      try {
        await _service.client!.auth.signInWithPassword(
          email: user.email!,
          password: currentPassword.trim(),
        );
      } catch (_) {
        throw Exception('Password saat ini salah. Konfirmasi password diperlukan untuk mengganti email.');
      }
    }

    try {
      await _service.client!.auth.updateUser(
        UserAttributes(email: cleanEmail),
      );
      await _service.saveKnownRegisteredEmail(cleanEmail);
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') || (e.code ?? '').contains('user_already_exists')) {
        throw Exception('Email tersebut sudah digunakan oleh akun lain.');
      }
      throw Exception('Gagal memperbarui email: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat memperbarui email.');
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final cleanCurrent = currentPassword.trim();
    final cleanNew = newPassword.trim();

    if (cleanCurrent.isEmpty) {
      throw Exception('Password saat ini wajib diisi.');
    }
    if (cleanNew.isEmpty) {
      throw Exception('Password baru wajib diisi.');
    }
    if (cleanNew.length < 6) {
      throw Exception('Password baru minimal harus 6 karakter.');
    }
    if (cleanNew == cleanCurrent) {
      throw Exception('Password baru tidak boleh sama dengan password saat ini.');
    }

    if (!_service.isLive) {
      final current = _service.mockCurrentUser;
      if (current == null) {
        throw Exception('Sesi tidak ditemukan.');
      }
      final currentEmail = current.email ?? 'admin@gudang.com';
      final expected = _service.getMockPassword(currentEmail);
      if (expected != null && cleanCurrent != expected) {
        throw Exception('Password saat ini salah. Silakan periksa kembali password Anda.');
      }

      await _service.updateMockPassword(
        email: currentEmail,
        newPassword: cleanNew,
      );
      return;
    }

    final user = _service.client?.auth.currentUser;
    if (user == null) {
      throw Exception('Sesi telah berakhir. Silakan masuk kembali.');
    }

    if (user.email != null) {
      try {
        await _service.client!.auth.signInWithPassword(
          email: user.email!,
          password: cleanCurrent,
        );
      } catch (_) {
        throw Exception('Password saat ini salah. Silakan periksa kembali password Anda.');
      }
    }

    try {
      await _service.client!.auth.updateUser(
        UserAttributes(password: cleanNew),
      );
    } on AuthException catch (e) {
      throw Exception('Gagal memperbarui password: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat memperbarui password.');
    }
  }
}
