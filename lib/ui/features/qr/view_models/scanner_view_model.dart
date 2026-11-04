import 'package:flutter/foundation.dart';
import 'package:gudang_mobile/data/models/product_model.dart';
import 'package:gudang_mobile/data/repositories/product_repository.dart';
import 'package:gudang_mobile/data/repositories/transaction_repository.dart';

enum ScannerMode {
  search,
  inbound,
  outbound,
}

class ScannerViewModel extends ChangeNotifier {
  final ProductRepository _productRepo;
  final TransactionRepository _transactionRepo;

  ScannerViewModel({
    ProductRepository? productRepo,
    TransactionRepository? transactionRepo,
  })  : _productRepo = productRepo ?? ProductRepository(),
        _transactionRepo = transactionRepo ?? TransactionRepository();

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ProductModel? _lastScannedProduct;
  ProductModel? get lastScannedProduct => _lastScannedProduct;

  void reset() {
    _lastScannedProduct = null;
    _errorMessage = null;
    _isProcessing = false;
    notifyListeners();
  }

  Future<ProductModel?> processScannedCode(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty) return null;

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final product = await _productRepo.getProductBySku(code);
      if (product == null) {
        _errorMessage = 'Barang dengan SKU "$code" tidak terdaftar di gudang.';
        _lastScannedProduct = null;
      } else {
        _lastScannedProduct = product;
        _errorMessage = null;
      }
      return product;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _lastScannedProduct = null;
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<bool> executeStockTransaction({
    required String productId,
    required String type,
    required int quantity,
    String? notes,
  }) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _transactionRepo.recordTransaction(
        productId: productId,
        type: type,
        quantity: quantity,
        notes: notes,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
