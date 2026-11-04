import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StockBadge extends StatelessWidget {
  final int stock;
  final int minStock;
  final bool compact;

  const StockBadge({
    super.key,
    required this.stock,
    required this.minStock,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = stock <= 0;
    final bool isLowStock = stock <= minStock && !isOutOfStock;

    final Color bgColor;
    final Color textColor;
    final String label;
    final IconData icon;

    if (isOutOfStock) {
      bgColor = const Color(0xFFFEE2E2);
      textColor = AppColors.critical;
      label = compact ? 'Habis' : 'Stok Habis (0)';
      icon = Icons.cancel_outlined;
    } else if (isLowStock) {
      bgColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFB45309);
      label = compact ? 'Kritis' : 'Menipis ($stock/$minStock)';
      icon = Icons.warning_amber_rounded;
    } else {
      bgColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF15803D);
      label = compact ? '$stock' : 'Tersedia ($stock)';
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
