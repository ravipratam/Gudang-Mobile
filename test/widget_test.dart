import 'package:flutter_test/flutter_test.dart';
import 'package:gudang_mobile/core/utils/formatters.dart';
import 'package:gudang_mobile/data/models/product_model.dart';
import 'package:gudang_mobile/data/models/stock_transaction_model.dart';
import 'package:gudang_mobile/data/repositories/product_repository.dart';
import 'package:gudang_mobile/data/repositories/transaction_repository.dart';

void main() {
  group('Warehouse Models & Logic Tests', () {
    test('ProductModel low stock & out of stock calculation', () {
      final productLow = ProductModel(
        id: 'test-1',
        sku: 'TEST-001',
        name: 'Item Uji Coba',
        stock: 4,
        minStock: 5,
      );

      expect(productLow.isLowStock, isTrue);
      expect(productLow.isOutOfStock, isFalse);

      final productEmpty = ProductModel(
        id: 'test-2',
        sku: 'TEST-002',
        name: 'Item Habis',
        stock: 0,
        minStock: 5,
      );

      expect(productEmpty.isLowStock, isTrue);
      expect(productEmpty.isOutOfStock, isTrue);

      final productSafe = ProductModel(
        id: 'test-3',
        sku: 'TEST-003',
        name: 'Item Aman',
        stock: 20,
        minStock: 5,
      );

      expect(productSafe.isLowStock, isFalse);
      expect(productSafe.isOutOfStock, isFalse);
    });

    test('ProductModel json serialization and deserialization', () {
      final product = ProductModel(
        id: 'prod-uuid-1',
        sku: 'SKU-888',
        name: 'Karton Box',
        categoryId: 3,
        categoryName: 'Kemasan',
        stock: 120,
        minStock: 20,
        location: 'Rak B-01',
      );

      final json = product.toJson();
      expect(json['sku'], 'SKU-888');
      expect(json['stock'], 120);
      expect(json['min_stock'], 20);

      final fromJson = ProductModel.fromJson({
        'id': 'prod-uuid-1',
        'sku': 'SKU-888',
        'name': 'Karton Box',
        'category_id': 3,
        'category_name': 'Kemasan',
        'stock': 120,
        'min_stock': 20,
        'location': 'Rak B-01',
      });

      expect(fromJson.sku, product.sku);
      expect(fromJson.categoryName, 'Kemasan');
    });

    test('StockTransactionModel inbound & outbound detection', () {
      final inTrx = StockTransactionModel(
        id: 'trx-1',
        productId: 'prod-1',
        type: 'IN',
        quantity: 10,
      );
      final outTrx = StockTransactionModel(
        id: 'trx-2',
        productId: 'prod-1',
        type: 'OUT',
        quantity: 5,
      );

      expect(inTrx.isInbound, isTrue);
      expect(inTrx.isOutbound, isFalse);
      expect(outTrx.isInbound, isFalse);
      expect(outTrx.isOutbound, isTrue);
    });

    test('Formatters.generateSku creates correct SKU pattern', () {
      final sku1 = Formatters.generateSku('Elektronik');
      expect(sku1.startsWith('ELE-'), isTrue);

      final sku2 = Formatters.generateSku('AB');
      expect(sku2.startsWith('ABX-'), isTrue);
    });

    test('ProductRepository search and find by SKU', () async {
      final repo = ProductRepository();
      final products = await repo.getProducts();
      expect(products.isNotEmpty, isTrue);

      // Search by SKU
      final found = await repo.getProductBySku('ELK-001');
      expect(found, isNotNull);
      expect(found!.sku, 'ELK-001');

      // Case insensitive SKU search
      final foundLower = await repo.getProductBySku('elk-001');
      expect(foundLower, isNotNull);
      expect(foundLower!.sku, 'ELK-001');
    });

    test('TransactionRepository Inbound and Outbound inventory movements', () async {
      final prodRepo = ProductRepository();
      final trxRepo = TransactionRepository();

      final initial = await prodRepo.getProductBySku('ELK-001');
      expect(initial, isNotNull);
      final initialStock = initial!.stock;

      // Inbound: +5
      await trxRepo.recordTransaction(
        productId: initial.id,
        type: 'IN',
        quantity: 5,
        notes: 'Uji Restock',
      );

      final afterIn = await prodRepo.getProductById(initial.id);
      expect(afterIn!.stock, initialStock + 5);

      // Outbound: -3
      await trxRepo.recordTransaction(
        productId: initial.id,
        type: 'OUT',
        quantity: 3,
        notes: 'Uji Keluar',
      );

      final afterOut = await prodRepo.getProductById(initial.id);
      expect(afterOut!.stock, initialStock + 5 - 3);

      // Outbound exceeding current stock should throw Exception
      expect(
        () async => await trxRepo.recordTransaction(
          productId: initial.id,
          type: 'OUT',
          quantity: 999999,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
