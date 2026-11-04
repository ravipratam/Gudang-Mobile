import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_constants.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/profile_model.dart';
import '../models/stock_transaction_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;
  SupabaseClient? get client => _client;

  bool get isLive => SupabaseConstants.isConfigured && _client != null;

  // ----------------------------------------------------
  // In-Memory Offline Store (Fallback when Supabase URL/Key is not yet set)
  // ----------------------------------------------------
  final Map<String, ProfileModel> _mockUsers = {
    'admin@gudang.com': ProfileModel(
      id: 'mock-user-123',
      fullName: 'Budi Santoso',
      role: 'admin',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    'staff@gudang.com': ProfileModel(
      id: 'mock-user-456',
      fullName: 'Siti Rahma',
      role: 'staff',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
  };

  final Map<String, String> _mockPasswords = {
    'admin@gudang.com': 'password123',
    'staff@gudang.com': 'password123',
  };

  final Set<String> _knownRegisteredEmails = {
    'admin@gudang.com',
    'staff@gudang.com',
  };

  ProfileModel? _mockCurrentUser;

  final List<CategoryModel> _mockCategories = [
    CategoryModel(id: 1, name: 'Elektronik'),
    CategoryModel(id: 2, name: 'Bahan Baku'),
    CategoryModel(id: 3, name: 'Kemasan & Packing'),
    CategoryModel(id: 4, name: 'Peralatan Gudang'),
    CategoryModel(id: 5, name: 'Suku Cadang'),
  ];

  late final List<ProductModel> _mockProducts = [
    ProductModel(
      id: 'prod-001',
      sku: 'ELK-001',
      name: 'Scanner Barcode Wireless 2.4G',
      categoryId: 1,
      categoryName: 'Elektronik',
      stock: 15,
      minStock: 5,
      location: 'Rak A-01',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    ProductModel(
      id: 'prod-002',
      sku: 'ELK-002',
      name: 'Printer Label Thermal Bluetooth 58mm',
      categoryId: 1,
      categoryName: 'Elektronik',
      stock: 8,
      minStock: 3,
      location: 'Rak A-02',
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
    ProductModel(
      id: 'prod-003',
      sku: 'KMS-001',
      name: 'Kardus Box Single Wall 20x20x10',
      categoryId: 3,
      categoryName: 'Kemasan & Packing',
      stock: 250,
      minStock: 50,
      location: 'Rak B-01',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    ProductModel(
      id: 'prod-004',
      sku: 'KMS-002',
      name: 'Bubble Wrap Tebal 50m x 1.25m',
      categoryId: 3,
      categoryName: 'Kemasan & Packing',
      stock: 4,
      minStock: 10, // Low stock warning!
      location: 'Rak B-02',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    ProductModel(
      id: 'prod-005',
      sku: 'PRL-001',
      name: 'Hand Pallet Truck Hydraulic 3 Ton',
      categoryId: 4,
      categoryName: 'Peralatan Gudang',
      stock: 2,
      minStock: 1,
      location: 'Zona C-Utama',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    ProductModel(
      id: 'prod-006',
      sku: 'KMS-003',
      name: 'Lakban Bening Daimaru 2 Inch',
      categoryId: 3,
      categoryName: 'Kemasan & Packing',
      stock: 3,
      minStock: 20, // Low stock warning!
      location: 'Rak B-03',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  late final List<StockTransactionModel> _mockTransactions = [
    StockTransactionModel(
      id: 'trx-001',
      productId: 'prod-001',
      productName: 'Scanner Barcode Wireless 2.4G',
      productSku: 'ELK-001',
      userId: 'mock-user-123',
      userName: 'Budi Santoso',
      type: 'IN',
      quantity: 10,
      notes: 'Penerimaan stok dari supplier pusat',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    StockTransactionModel(
      id: 'trx-002',
      productId: 'prod-004',
      productName: 'Bubble Wrap Tebal 50m x 1.25m',
      productSku: 'KMS-002',
      userId: 'mock-user-123',
      userName: 'Budi Santoso',
      type: 'OUT',
      quantity: 6,
      notes: 'Pengiriman ke divisi packing shift pagi',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  ProfileModel? get mockCurrentUser => _mockCurrentUser;

  Future<void> setMockCurrentUser(ProfileModel? user) async {
    _mockCurrentUser = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (user == null) {
        await prefs.remove('saved_mock_user_email');
      } else {
        String? emailFound;
        for (final entry in _mockUsers.entries) {
          if (entry.value.id == user.id) {
            emailFound = entry.key;
            break;
          }
        }
        if (emailFound != null) {
          await prefs.setString('saved_mock_user_email', emailFound);
        }
      }
    } catch (_) {}
  }

  ProfileModel? getMockUser(String email) => _mockUsers[email.trim().toLowerCase()];

  String? getMockPassword(String email) => _mockPasswords[email.trim().toLowerCase()];

  bool isMockUserRegistered(String email) => _mockUsers.containsKey(email.trim().toLowerCase());

  bool isKnownRegisteredEmail(String email) =>
      _knownRegisteredEmails.contains(email.trim().toLowerCase());

  Future<void> saveKnownRegisteredEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    _knownRegisteredEmails.add(cleanEmail);
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('known_registered_emails') ?? [];
      if (!list.contains(cleanEmail)) {
        list.add(cleanEmail);
        await prefs.setStringList('known_registered_emails', list);
      }
    } catch (_) {}
  }

  Future<void> registerMockUser(String email, ProfileModel profile, {String? password}) async {
    final cleanEmail = email.trim().toLowerCase();
    _mockUsers[cleanEmail] = profile;
    if (password != null && password.isNotEmpty) {
      _mockPasswords[cleanEmail] = password;
    } else {
      _mockPasswords[cleanEmail] = 'password123';
    }
    _mockCurrentUser = profile;
    await saveKnownRegisteredEmail(cleanEmail);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_mock_user_email', cleanEmail);
      await prefs.setString('mock_name_$cleanEmail', profile.fullName);
      await prefs.setString('mock_role_$cleanEmail', profile.role);
      await prefs.setString('mock_id_$cleanEmail', profile.id);
      if (password != null && password.isNotEmpty) {
        await prefs.setString('mock_pwd_$cleanEmail', password);
      }
    } catch (_) {}
  }

  List<CategoryModel> get mockCategories => _mockCategories;
  List<ProductModel> get mockProducts => _mockProducts;
  List<StockTransactionModel> get mockTransactions => _mockTransactions;

  /// Initialize Supabase Flutter Client
  Future<void> initialize() async {
    if (SupabaseConstants.isConfigured) {
      try {
        await Supabase.initialize(
          url: SupabaseConstants.supabaseUrl,
          publishableKey: SupabaseConstants.supabaseAnonKey,
        );
        _client = Supabase.instance.client;
        if (kDebugMode) {
          print('✅ Supabase connected successfully to: ${SupabaseConstants.supabaseUrl}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Supabase connection failed: $e. Running in Offline Mock Mode.');
        }
      }
    } else {
      if (kDebugMode) {
        print('ℹ️ Supabase not yet configured. Running in Offline Mock Mode.');
      }
    }

    // Load persisted registered emails and mock passwords
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('known_registered_emails');
      if (list != null) {
        _knownRegisteredEmails.addAll(list);
      }
      for (final email in _knownRegisteredEmails) {
        final pwd = prefs.getString('mock_pwd_$email');
        if (pwd != null) {
          _mockPasswords[email] = pwd;
        }
        final name = prefs.getString('mock_name_$email');
        final role = prefs.getString('mock_role_$email');
        final id = prefs.getString('mock_id_$email');
        if (name != null && role != null && id != null) {
          _mockUsers[email] = ProfileModel(
            id: id,
            fullName: name,
            role: role,
          );
        }
      }
    } catch (_) {}

    // Restore saved mock session if offline/mock mode
    if (!isLive) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedEmail = prefs.getString('saved_mock_user_email');
        if (savedEmail != null && savedEmail.isNotEmpty) {
          final user = getMockUser(savedEmail);
          if (user != null) {
            _mockCurrentUser = user;
          }
        }
      } catch (_) {}
    }
  }
}
