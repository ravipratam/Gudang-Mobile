import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../core/custom_button.dart';
import '../../../core/custom_text_field.dart';
import '../../../core/profile_avatar.dart';
import '../../auth/view_models/auth_view_model.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final TextEditingController _passwordConfirmController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  Uint8List? _newAvatarBytes;
  String? _newAvatarFileName;
  String? _newAvatarMimeType;
  bool _removeAvatarRequested = false;

  bool _isSaving = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthViewModel>().profile;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final ext = picked.name.contains('.') ? picked.name.split('.').last.toLowerCase() : 'jpg';
        String mimeType = 'image/jpeg';
        if (ext == 'png') {
          mimeType = 'image/png';
        } else if (ext == 'webp') {
          mimeType = 'image/webp';
        }

        setState(() {
          _newAvatarBytes = bytes;
          _newAvatarFileName = picked.name;
          _newAvatarMimeType = mimeType;
          _removeAvatarRequested = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    }
  }

  void _showAvatarOptionsSheet() {
    final currentAvatar = context.read<AuthViewModel>().profile?.avatarUrl;
    final hasAvatar = (_newAvatarBytes != null && !_removeAvatarRequested) ||
        (currentAvatar != null && currentAvatar.isNotEmpty && !_removeAvatarRequested);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Ubah Foto Profil',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.camera_alt, color: AppColors.primary),
                  ),
                  title: const Text('Ambil Foto dari Kamera'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.photo_library, color: AppColors.accent),
                  ),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (hasAvatar)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.critical.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline, color: AppColors.critical),
                    ),
                    title: const Text('Hapus Foto Profil', style: TextStyle(color: AppColors.critical)),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _newAvatarBytes = null;
                        _newAvatarFileName = null;
                        _newAvatarMimeType = null;
                        _removeAvatarRequested = true;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final authVm = context.read<AuthViewModel>();
    final currentProfile = authVm.profile;

    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim().toLowerCase();
    final currentEmail = (currentProfile?.email ?? '').trim().toLowerCase();

    final isNameChanged = newName != (currentProfile?.fullName ?? '').trim();
    final isEmailChanged = newEmail.isNotEmpty && newEmail != currentEmail;
    final isAvatarUpdated = _newAvatarBytes != null;
    final isAvatarRemoved = _removeAvatarRequested && (currentProfile?.avatarUrl != null);

    if (!isNameChanged && !isEmailChanged && !isAvatarUpdated && !isAvatarRemoved) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Update Avatar if requested
      if (isAvatarUpdated) {
        final avatarSuccess = await authVm.updateAvatarBytes(
          bytes: _newAvatarBytes!,
          fileName: _newAvatarFileName ?? 'avatar.jpg',
          mimeType: _newAvatarMimeType ?? 'image/jpeg',
        );
        if (!avatarSuccess) {
          throw Exception(authVm.errorMessage ?? 'Gagal mengunggah foto profil.');
        }
      } else if (isAvatarRemoved) {
        final removeSuccess = await authVm.removeAvatar();
        if (!removeSuccess) {
          throw Exception(authVm.errorMessage ?? 'Gagal menghapus foto profil.');
        }
      }

      // 2. Update Name if changed
      if (isNameChanged) {
        final nameSuccess = await authVm.updateProfileName(newName);
        if (!nameSuccess) {
          throw Exception(authVm.errorMessage ?? 'Gagal memperbarui nama lengkap.');
        }
      }

      // 3. Update Email if changed
      if (isEmailChanged) {
        final emailSuccess = await authVm.updateEmail(
          newEmail: newEmail,
          currentPassword: _passwordConfirmController.text.trim(),
        );
        if (!emailSuccess) {
          throw Exception(authVm.errorMessage ?? 'Gagal memperbarui email.');
        }
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('Profil berhasil diperbarui.')),
            ],
          ),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(errorMsg)),
            ],
          ),
          backgroundColor: AppColors.critical,
        ),
      );
    }
  }

  Widget _buildAvatarPreview() {
    final authVm = context.watch<AuthViewModel>();
    final currentProfile = authVm.profile;

    if (_removeAvatarRequested) {
      return ProfileAvatar(
        name: _nameController.text.isNotEmpty ? _nameController.text : (currentProfile?.fullName ?? 'U'),
        radius: 50,
        showEditBadge: true,
        onTap: _showAvatarOptionsSheet,
      );
    }

    if (_newAvatarBytes != null) {
      return GestureDetector(
        onTap: _showAvatarOptionsSheet,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.memory(
                  _newAvatarBytes!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    return ProfileAvatar(
      avatarUrl: currentProfile?.avatarUrl,
      name: _nameController.text.isNotEmpty ? _nameController.text : (currentProfile?.fullName ?? 'U'),
      radius: 50,
      showEditBadge: true,
      onTap: _showAvatarOptionsSheet,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = (context.watch<AuthViewModel>().profile?.email ?? '').trim().toLowerCase();
    final isEmailChanging = _emailController.text.trim().toLowerCase() != currentEmail;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profil'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar Center Card
                Center(
                  child: Column(
                    children: [
                      _buildAvatarPreview(),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _showAvatarOptionsSheet,
                        icon: const Icon(Icons.photo_camera, size: 18),
                        label: const Text('Ubah Foto Profil'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Data Pribadi Akun',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Perbarui nama lengkap dan email akun gudang Anda.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),

                      // Nama Lengkap Field
                      CustomTextField(
                        label: 'Nama Lengkap',
                        hint: 'Masukkan nama lengkap Anda',
                        controller: _nameController,
                        prefixIcon: const Icon(Icons.person_outline, size: 20, color: AppColors.textSecondary),
                        onChanged: (_) => setState(() {}),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama lengkap tidak boleh kosong.';
                          }
                          if (val.trim().length < 2) {
                            return 'Nama minimal terdiri dari 2 karakter.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Email Field
                      CustomTextField(
                        label: 'Alamat Email',
                        hint: 'contoh@gudang.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.textSecondary),
                        onChanged: (_) => setState(() {}),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Email tidak boleh kosong.';
                          }
                          final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegExp.hasMatch(val.trim())) {
                            return 'Format email tidak valid.';
                          }
                          return null;
                        },
                      ),

                      // Password confirmation when email is changed
                      if (isEmailChanging) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, size: 18, color: AppColors.accent),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Perubahan email memerlukan konfirmasi password Anda demi keamanan akun.',
                                  style: TextStyle(fontSize: 12, color: AppColors.accent),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          label: 'Password Saat Ini (Konfirmasi)',
                          hint: 'Masukkan password untuk ganti email',
                          controller: _passwordConfirmController,
                          obscureText: _obscurePassword,
                          prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.textSecondary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (val) {
                            if (isEmailChanging && (val == null || val.trim().isEmpty)) {
                              return 'Password saat ini diperlukan saat mengubah email.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                CustomButton(
                  text: 'Simpan Perubahan',
                  icon: Icons.save_outlined,
                  isLoading: _isSaving,
                  onPressed: _saveChanges,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
