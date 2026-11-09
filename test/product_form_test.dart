import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gudang_mobile/core/theme/app_theme.dart';
import 'package:gudang_mobile/data/models/product_model.dart';
import 'package:gudang_mobile/data/repositories/product_repository.dart';
import 'package:gudang_mobile/ui/core/custom_button.dart';
import 'package:gudang_mobile/ui/features/products/view_models/product_view_model.dart';
import 'package:gudang_mobile/ui/features/products/views/product_form_view.dart';

class MockPostgrestDuplicateProductRepo extends ProductRepository {
  @override
  Future<List<ProductModel>> getProducts({
    String? query,
    int? categoryId,
    bool onlyLowStock = false,
  }) async => [];

  @override
  Future<ProductModel> addProduct(ProductModel product) async {
    throw const PostgrestException(
      message: 'duplicate key value violates unique constraint "product_sku_key"',
      code: '23505',
      details: 'Conflict',
    );
  }
}

void main() {
  group('ProductFormView & SKU Duplicate Notification Tests', () {
    testWidgets('Test ProductFormView render and SKU empty by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ProductViewModel()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProductFormView(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.byType(ProductFormView), findsOneWidget);

      final skuField = find.byType(TextFormField).at(0);
      expect(tester.widget<TextFormField>(skuField).controller?.text, '');

      // Tapping "Auto" button should generate SKU
      final autoButton = find.widgetWithText(OutlinedButton, 'Auto');
      expect(autoButton, findsOneWidget);
      await tester.tap(autoButton);
      await tester.pump();

      expect(tester.widget<TextFormField>(skuField).controller?.text.isNotEmpty, isTrue);
      expect(tester.widget<TextFormField>(skuField).controller?.text.startsWith('PRD-'), isTrue);
    });

    test('ProductRepository throws clean SKU duplicate error when SKU already exists', () async {
      final repo = ProductRepository();
      final duplicateProduct = ProductModel(
        id: 'test-new-id',
        sku: 'ELK-001',
        name: 'Produk Baru Duplikat',
        stock: 10,
        minStock: 2,
      );

      expect(
        () => repo.addProduct(duplicateProduct),
        throwsA(
          predicate((e) =>
              e is Exception &&
              e.toString().contains('SKU "ELK-001" sudah terdaftar.')),
        ),
      );
    });

    test('ProductViewModel parses PostgrestException duplicate constraint into friendly SKU message', () async {
      final vm = ProductViewModel(productRepo: MockPostgrestDuplicateProductRepo());
      final duplicateProduct = ProductModel(
        id: 'test-prod',
        sku: 'ELK-001',
        name: 'Barcode Scanner Extra',
        stock: 5,
        minStock: 2,
      );

      final success = await vm.addProduct(duplicateProduct);
      expect(success, isFalse);
      expect(vm.errorMessage, 'SKU "ELK-001" sudah terdaftar.');
    });

    testWidgets('ProductFormView displays friendly SnackBar when SKU already exists', (tester) async {
      final vm = ProductViewModel(productRepo: MockPostgrestDuplicateProductRepo());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ProductViewModel>.value(value: vm),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProductFormView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter duplicate SKU 'ELK-001' and Name
      final textFields = find.byType(TextFormField);
      final skuField = textFields.at(0);
      final nameField = textFields.at(1);
      final submitButton = find.widgetWithText(CustomButton, 'Tambah ke Gudang');

      await tester.enterText(skuField, 'ELK-001');
      await tester.enterText(nameField, 'Scanner Barcode Tambahan');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify that the friendly message is displayed in SnackBar and NOT PostgrestException
      expect(find.text('SKU "ELK-001" sudah terdaftar.'), findsOneWidget);
      expect(find.textContaining('PostgrestException'), findsNothing);
      expect(find.textContaining('product_sku_key'), findsNothing);
    });
  });
}
