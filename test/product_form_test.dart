import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gudang_mobile/core/theme/app_theme.dart';
import 'package:gudang_mobile/ui/features/products/view_models/product_view_model.dart';
import 'package:gudang_mobile/ui/features/products/views/product_form_view.dart';

void main() {
  testWidgets('Test ProductFormView render', (WidgetTester tester) async {
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
  });
}
