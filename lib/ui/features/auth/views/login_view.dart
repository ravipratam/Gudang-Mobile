import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gudang_mobile/core/constants/app_colors.dart';
import 'package:gudang_mobile/ui/core/custom_button.dart';
import 'package:gudang_mobile/ui/core/custom_text_field.dart';
import '../view_models/auth_view_model.dart';
import 'register_view.dart';
import 'reset_password_view.dart';
import 'auth_gate.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authVm = context.read<AuthViewModel>();
    final success = await authVm.signIn(
      _emailController.text,
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } else if (mounted && authVm.errorMessage != null) {
      final error = authVm.errorMessage!;
      final isNotRegistered = error.toLowerCase().contains('belum terdaftar') ||
          error.toLowerCase().contains('belum ada') ||
          error.toLowerCase().contains('tidak ditemukan');
      final isWrongPassword = error.toLowerCase().contains('password salah') ||
          error.toLowerCase().contains('kata sandi salah');

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.critical,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                isNotRegistered
                    ? Icons.person_off_outlined
                    : isWrongPassword
                        ? Icons.lock_clock_outlined
                        : Icons.error_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isNotRegistered
                          ? 'Akun Tidak Ditemukan'
                          : isWrongPassword
                              ? 'Password Salah'
                              : 'Gagal Masuk',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      error,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          action: isNotRegistered
              ? SnackBarAction(
                  label: 'DAFTAR',
                  textColor: Colors.yellowAccent,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterView()),
                    );
                  },
                )
              : isWrongPassword
                  ? SnackBarAction(
                      label: 'LUPA?',
                      textColor: Colors.yellowAccent,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ResetPasswordView()),
                        );
                      },
                    )
                  : null,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Brand Logo & Name
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warehouse_rounded,
                        size: 42,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Gudang Mobile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Warehouse Management System',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Inline Error Notification Banner
                  if (authVm.errorMessage != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.critical.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.critical.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            authVm.errorMessage!.toLowerCase().contains('belum terdaftar')
                                ? Icons.person_off_outlined
                                : authVm.errorMessage!.toLowerCase().contains('password salah')
                                    ? Icons.lock_clock_outlined
                                    : Icons.error_outline_rounded,
                            color: AppColors.critical,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authVm.errorMessage!.toLowerCase().contains('belum terdaftar')
                                      ? 'Akun Belum Terdaftar'
                                      : authVm.errorMessage!.toLowerCase().contains('password salah')
                                          ? 'Password Salah'
                                          : 'Gagal Masuk',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.critical,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  authVm.errorMessage!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade900,
                                    height: 1.3,
                                  ),
                                ),
                                if (authVm.errorMessage!.toLowerCase().contains('belum terdaftar')) ...[
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () {
                                      context.read<AuthViewModel>().clearError();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const RegisterView(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Daftar akun baru sekarang →',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ] else if (authVm.errorMessage!.toLowerCase().contains('password salah')) ...[
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () {
                                      context.read<AuthViewModel>().clearError();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const ResetPasswordView(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Lupa password? Atur ulang di sini →',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                            onPressed: () => context.read<AuthViewModel>().clearError(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Email Field
                  CustomTextField(
                    label: 'Email',
                    hint: 'Masukkan Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    onChanged: (_) {
                      if (authVm.errorMessage != null) {
                        context.read<AuthViewModel>().clearError();
                      }
                    },
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                      if (!v.contains('@')) return 'Format email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Password Field
                  CustomTextField(
                    label: 'Password',
                    hint: 'Masukkan Password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    onChanged: (_) {
                      if (authVm.errorMessage != null) {
                        context.read<AuthViewModel>().clearError();
                      }
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password wajib diisi';
                      if (v.length < 6) return 'Password minimal 6 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ResetPasswordView()),
                        );
                      },
                      child: const Text(
                        'Lupa Password?',
                        style: TextStyle(fontSize: 13, color: AppColors.primaryLight),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Login Button
                  CustomButton(
                    text: 'Masuk ke Gudang',
                    icon: Icons.login,
                    isLoading: authVm.isLoading,
                    onPressed: _onLogin,
                  ),
                  const SizedBox(height: 16),

                  // Register Link Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterView(),
                            ),
                          );
                        },
                        child: const Text(
                          'Daftar Sekarang',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
