import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/supabase_service.dart';

class ProductRepository {
  final SupabaseService _service;

  ProductRepository({SupabaseService? service}) : _service = service ?? SupabaseService();

  Future<List<CategoryModel>> getCategories() async {
    if (!_service.isLive) {
      await Future.delayed(const Duration(milliseconds: 150));
      return List.unmodifiable(_service.mockCategories);
    }

    final data = await _service.client!
        .from('categories')
        .select()
        .order('id', ascending: true);

    return (data as List).map((json) => CategoryModel.fromJson(json)).toList();
  }

  Future<List<ProductModel>> getProducts({
    String? query,
    int? categoryId,
    bool onlyLowStock = false,
  }) async {
    if (!_service.isLive) {
      await Future.delayed(const Duration(milliseconds: 200));
      var list = List<ProductModel>.from(_service.mockProducts);

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        list = list.where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            (p.location != null && p.location!.toLowerCase().contains(q))).toList();
      }

      if (categoryId != null) {
        list = list.where((p) => p.categoryId == categoryId).toList();
      }

      if (onlyLowStock) {
        list = list.where((p) => p.isLowStock).toList();
      }

      return list;
    }

    var request = _service.client!
        .from('products')
        .select('*, categories(name)')
        .order('created_at', ascending: false);

    final data = await request;
    var results = (data as List).map((json) => ProductModel.fromJson(json)).toList();

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      results = results.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          (p.location != null && p.location!.toLowerCase().contains(q))).toList();
    }

    if (categoryId != null) {
      results = results.where((p) => p.categoryId == categoryId).toList();
    }

    if (onlyLowStock) {
      results = results.where((p) => p.isLowStock).toList();
    }

    return results;
  }

  Future<ProductModel?> getProductById(String id) async {
    if (!_service.isLive) {
      return _service.mockProducts.cast<ProductModel?>().firstWhere(
            (p) => p?.id == id,
            orElse: () => null,
          );
    }

    final data = await _service.client!
        .from('products')
        .select('*, categories(name)')
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return ProductModel.fromJson(data);
  }

  Future<ProductModel?> getProductBySku(String sku) async {
    final cleanSku = sku.trim().toUpperCase();

    if (!_service.isLive) {
      return _service.mockProducts.cast<ProductModel?>().firstWhere(
            (p) => p?.sku.toUpperCase() == cleanSku,
            orElse: () => null,
          );
    }

    final data = await _service.client!
        .from('products')
        .select('*, categories(name)')
        .ilike('sku', cleanSku)
        .maybeSingle();

    if (data == null) return null;
    return ProductModel.fromJson(data);
  }

  Future<ProductModel> addProduct(ProductModel product) async {
    final cleanSku = product.sku.trim().toUpperCase();

    if (!_service.isLive) {
      await Future.delayed(const Duration(milliseconds: 300));
      // Check SKU uniqueness
      final exists = _service.mockProducts.any(
        (p) => p.sku.toUpperCase() == cleanSku,
      );
      if (exists) {
        throw Exception('SKU "$cleanSku" sudah terdaftar.');
      }

      final categoryName = _service.mockCategories
          .cast<CategoryModel?>()
          .firstWhere((c) => c?.id == product.categoryId, orElse: () => null)
          ?.name;

      final newProduct = product.copyWith(
        id: 'prod-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999)}',
        sku: cleanSku,
        categoryName: categoryName,
        createdAt: DateTime.now(),
      );
      _service.mockProducts.insert(0, newProduct);
      return newProduct;
    }

    try {
      final data = await _service.client!
          .from('products')
          .insert({
            'sku': cleanSku,
            'name': product.name.trim(),
            if (product.categoryId != null) 'category_id': product.categoryId,
            'stock': product.stock,
            'min_stock': product.minStock,
            if (product.location != null) 'location': product.location!.trim(),
          })
          .select('*, categories(name)')
          .single();

      return ProductModel.fromJson(data);
    } on PostgrestException catch (e) {
      if (e.code == '23505' ||
          e.message.toLowerCase().contains('product_sku_key') ||
          e.message.toLowerCase().contains('sku') ||
          e.message.toLowerCase().contains('duplicate key')) {
        throw Exception('SKU "$cleanSku" sudah terdaftar.');
      }
      throw Exception('Gagal menambahkan barang: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat menambahkan barang.');
    }
  }

  Future<ProductModel> updateProduct(ProductModel product) async {
    final cleanSku = product.sku.trim().toUpperCase();

    if (!_service.isLive) {
      await Future.delayed(const Duration(milliseconds: 300));
      final index = _service.mockProducts.indexWhere((p) => p.id == product.id);
      if (index == -1) {
        throw Exception('Barang tidak ditemukan.');
      }

      // Check SKU uniqueness among other products
      final skuExists = _service.mockProducts.any(
        (p) => p.id != product.id && p.sku.toUpperCase() == cleanSku,
      );
      if (skuExists) {
        throw Exception('SKU "$cleanSku" sudah terdaftar.');
      }

      final categoryName = _service.mockCategories
          .cast<CategoryModel?>()
          .firstWhere((c) => c?.id == product.categoryId, orElse: () => null)
          ?.name;

      final updated = product.copyWith(
        sku: cleanSku,
        categoryName: categoryName,
      );
      _service.mockProducts[index] = updated;
      return updated;
    }

    try {
      final data = await _service.client!
          .from('products')
          .update({
            'sku': cleanSku,
            'name': product.name.trim(),
            'category_id': product.categoryId,
            'stock': product.stock,
            'min_stock': product.minStock,
            'location': product.location?.trim(),
          })
          .eq('id', product.id)
          .select('*, categories(name)')
          .single();

      return ProductModel.fromJson(data);
    } on PostgrestException catch (e) {
      if (e.code == '23505' ||
          e.message.toLowerCase().contains('product_sku_key') ||
          e.message.toLowerCase().contains('sku') ||
          e.message.toLowerCase().contains('duplicate key')) {
        throw Exception('SKU "$cleanSku" sudah terdaftar.');
      }
      throw Exception('Gagal memperbarui barang: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat memperbarui barang.');
    }
  }

  Future<void> deleteProduct(String id) async {
    if (!_service.isLive) {
      await Future.delayed(const Duration(milliseconds: 200));
      _service.mockProducts.removeWhere((p) => p.id == id);
      return;
    }

    try {
      await _service.client!.from('products').delete().eq('id', id);
    } on PostgrestException catch (e) {
      if (e.code == '23503' || e.message.toLowerCase().contains('foreign key')) {
        throw Exception('Barang tidak dapat dihapus karena memiliki riwayat transaksi.');
      }
      throw Exception('Gagal menghapus barang: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat menghapus barang.');
    }
  }
}
