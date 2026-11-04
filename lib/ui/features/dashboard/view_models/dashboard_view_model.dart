import 'package:flutter/foundation.dart';
import 'package:gudang_mobile/data/models/product_model.dart';
import 'package:gudang_mobile/data/models/stock_transaction_model.dart';
import 'package:gudang_mobile/data/repositories/product_repository.dart';
import 'package:gudang_mobile/data/repositories/transaction_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final ProductRepository _productRepo;
  final TransactionRepository _transactionRepo;

  DashboardViewModel({
    ProductRepository? productRepo,
    TransactionRepository? transactionRepo,
  })  : _productRepo = productRepo ?? ProductRepository(),
        _transactionRepo = transactionRepo ?? TransactionRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _totalProducts = 0;
  int get totalProducts => _totalProducts;

  int _totalStock = 0;
  int get totalStock => _totalStock;

  int _lowStockCount = 0;
  int get lowStockCount => _lowStockCount;

  List<ProductModel> _lowStockProducts = [];
  List<ProductModel> get lowStockProducts => _lowStockProducts;

  List<StockTransactionModel> _recentTransactions = [];
  List<StockTransactionModel> get recentTransactions => _recentTransactions;

  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final products = await _productRepo.getProducts();
      _totalProducts = products.length;
      _totalStock = products.fold(0, (sum, p) => sum + p.stock);
      _lowStockProducts = products.where((p) => p.isLowStock).toList();
      _lowStockCount = _lowStockProducts.length;

      _recentTransactions = await _transactionRepo.getTransactions(limit: 5);
    } catch (_) {
      // Keep previous state if any
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
