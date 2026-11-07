import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gudang_mobile/data/models/category_model.dart';
import 'package:gudang_mobile/data/models/product_model.dart';
import 'package:gudang_mobile/data/repositories/product_repository.dart';

class ProductViewModel extends ChangeNotifier {
  final ProductRepository _productRepo;

  ProductViewModel({ProductRepository? productRepo})
      : _productRepo = productRepo ?? ProductRepository();

  List<ProductModel> _products = [];
  List<ProductModel> get products => _products;

  List<CategoryModel> _categories = [];
  List<CategoryModel> get categories => _categories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _searchQuery = '';
  int? _selectedCategoryId;
  bool _filterLowStockOnly = false;

  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  bool get filterLowStockOnly => _filterLowStockOnly;

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchProducts();
  }

  void setSelectedCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    fetchProducts();
  }

  void toggleLowStockFilter() {
    _filterLowStockOnly = !_filterLowStockOnly;
    fetchProducts();
  }

  Future<void> fetchCategories() async {
    try {
      _categories = await _productRepo.getCategories();
      notifyListeners();
    } catch (_) {}
  }

  String _parseErrorMessage(Object e, {String? defaultSku}) {
    final errStr = e.toString();
    if (e is PostgrestException ||
        errStr.contains('product_sku_key') ||
        (errStr.contains('23505') && errStr.toLowerCase().contains('sku'))) {
      final sku = (defaultSku != null && defaultSku.trim().isNotEmpty)
          ? defaultSku.trim().toUpperCase()
          : null;
      return sku != null ? 'SKU "$sku" sudah terdaftar.' : 'SKU sudah terdaftar.';
    }
    return errStr.replaceFirst('Exception: ', '');
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _productRepo.getProducts(
        query: _searchQuery,
        categoryId: _selectedCategoryId,
        onlyLowStock: _filterLowStockOnly,
      );
    } catch (e) {
      _errorMessage = _parseErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct(ProductModel product) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _productRepo.addProduct(product);
      await fetchProducts();
      return true;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e, defaultSku: product.sku);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _productRepo.updateProduct(product);
      await fetchProducts();
      return true;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e, defaultSku: product.sku);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduct(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _productRepo.deleteProduct(id);
      await fetchProducts();
      return true;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
