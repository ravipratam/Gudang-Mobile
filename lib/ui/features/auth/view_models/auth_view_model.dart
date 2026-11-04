import 'package:flutter/foundation.dart';
import 'package:gudang_mobile/data/models/profile_model.dart';
import 'package:gudang_mobile/data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  ProfileModel? _profile;
  ProfileModel? get profile => _profile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isCheckingAuth = true;
  bool get isCheckingAuth => _isCheckingAuth;

  bool _hasCheckedInitialAuth = false;
  bool get hasCheckedInitialAuth => _hasCheckedInitialAuth;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  bool get hasActiveSession => _authRepository.isAuthenticated;

  bool get isAuthenticated => _profile != null && _authRepository.isAuthenticated;

  bool get isAdmin => _profile?.isAdmin ?? false;

  Future<void> checkAuthStatus({bool force = false}) async {
    // If we already finished initial check and user is authenticated, do not show splash loading screen
    if (_hasCheckedInitialAuth && !force && _profile != null) {
      return refreshProfile();
    }

    _isCheckingAuth = true;
    _isLoading = true;
    notifyListeners();
    try {
      _profile = await _authRepository.getCurrentProfile();
    } catch (_) {
      _profile = null;
    } finally {
      _hasCheckedInitialAuth = true;
      _isLoading = false;
      _isCheckingAuth = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    try {
      final updated = await _authRepository.getCurrentProfile();
      if (updated != null && updated != _profile) {
        _profile = updated;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _authRepository.signIn(
        email: email,
        password: password,
      );
      _errorMessage = null;
      _hasCheckedInitialAuth = true;
      _isCheckingAuth = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String role = 'staff',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _authRepository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      _errorMessage = null;
      _hasCheckedInitialAuth = true;
      _isCheckingAuth = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authRepository.signOut();
      _profile = null;
      _hasCheckedInitialAuth = true;
      _isCheckingAuth = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
