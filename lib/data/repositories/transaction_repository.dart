import 'dart:math';
import '../models/stock_transaction_model.dart';
import '../services/supabase_service.dart';

class TransactionRepository {
  final SupabaseService _service;

  TransactionRepository({SupabaseService? service}) : _service = service ?? SupabaseService();

  /// Records an inbound (IN) or outbound (OUT) stock movement
  Future<StockTransactionModel> recordTransaction({
    required String productId,
    required String type, // 'IN' or 'OUT'
    required int quantity,
    String? notes,
  }) async {
    final cleanType = type.trim().toUpperCase();
    if (cleanType != 'IN' && cleanType != 'OUT') {
      throw Exception('Tipe transaksi harus IN atau OUT.');
    }
    if (quantity <= 0) {
      throw Exception('Jumlah transaksi harus lebih besar dari 0.');
    }

    if (!_service.isLive) {
      await Future.delayed(const Duration(milliseconds: 300));
      final pIndex = _service.mockProducts.indexWhere((p) => p.id == productId);
      if (pIndex == -1) {
        throw Exception('Barang tidak ditemukan.');
      }

      final product = _service.mockProducts[pIndex];
      if (cleanType == 'OUT' && product.stock < quantity) {
        throw Exception(
          'Stok tidak mencukupi. Stok saat ini: ${product.stock}, diminta: $quantity.',
        );
      }

      final newStock = cleanType == 'IN'
          ? product.stock + quantity
          : product.stock - quantity;

      _service.mockProducts[pIndex] = product.copyWith(stock: newStock);

      final user = _service.mockCurrentUser;
      final trx = StockTransactionModel(
        id: 'trx-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999)}',
        productId: product.id,
        productName: product.name,
        productSku: product.sku,
        userId: user?.id,
        userName: user?.fullName ?? 'Staf Gudang',
        type: cleanType,
        quantity: quantity,
        notes: notes,
        createdAt: DateTime.now(),
      );

      _service.mockTransactions.insert(0, trx);
      return trx;
    }

    // Call PostgreSQL stored procedure in Supabase
    final response = await _service.client!.rpc(
      'record_stock_transaction',
      params: {
        'p_product_id': productId,
        'p_type': cleanType,
        'p_quantity': quantity,
        if (notes != null && notes.isNotEmpty) 'p_notes': notes.trim(),
      },
    );

    final resMap = response is Map ? response : {};
    final trxId = resMap['transaction_id']?.toString() ??
        'trx-${DateTime.now().millisecondsSinceEpoch}';

    return StockTransactionModel(
      id: trxId,
      productId: productId,
      type: cleanType,
      quantity: quantity,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  Future<List<StockTransactionModel>> getTransactions({
    int limit = 50,
    String? productId,
  }) async {
    if (!_service.isLive) {
      await Future.delayed(const Duration(milliseconds: 200));
      var list = List<StockTransactionModel>.from(_service.mockTransactions);
      if (productId != null) {
        list = list.where((t) => t.productId == productId).toList();
      }
      return list.take(limit).toList();
    }

    var filterBuilder = _service.client!
        .from('stock_transactions')
        .select('*, products(name, sku), profiles(full_name)');

    if (productId != null) {
      filterBuilder = filterBuilder.eq('product_id', productId);
    }

    final data = await filterBuilder
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).map((json) => StockTransactionModel.fromJson(json)).toList();
  }
}
