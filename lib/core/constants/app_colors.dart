import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color primary = Color(0xFF1E3A8A); // Deep Slate Navy
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color accent = Color(0xFF0284C7); // Sky Blue

  // Status & Actions
  static const Color inbound = Color(0xFF10B981); // Emerald Green for Inbound/Stock +
  static const Color outbound = Color(0xFFF97316); // Amber/Orange for Outbound/Stock -
  static const Color critical = Color(0xFFEF4444); // Red for Low Stock & Errors
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
}
