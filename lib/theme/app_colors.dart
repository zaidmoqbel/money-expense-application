import 'package:flutter/material.dart';

/// App color scheme - converted from globals.css
class AppColors {
  // Primary colors (Teal theme)
  static const Color primary = Color(0xFF14B8A6); // Teal
  static const Color primaryLight = Color(0xFF5EEAD4);
  static const Color primaryDark = Color(0xFF0F766E);
  
  // Success/Pastel Green
  static const Color success = Color(0xFF86EFAC);
  static const Color successDark = Color(0xFF4ADE80);
  
  // Warning/Orange
  static const Color warning = Color(0xFFFB923C);
  static const Color warningDark = Color(0xFFF97316);
  
  // Background colors
  static const Color background = Color(0xFFF9FAFB); // Soft gray
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color inputBackground = Color(0xFFF3F3F5);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  
  // Border and divider
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFECECF0);
  
  // Semantic colors
  static const Color error = Color(0xFFD4183D);
  static const Color errorLight = Color(0xFFFEE2E2);
  
  // Chart colors
  static const Color chart1 = Color(0xFFFF6B6B); // Red
  static const Color chart2 = Color(0xFF4ECDC4); // Cyan
  static const Color chart3 = Color(0xFF45B7D1); // Blue
  static const Color chart4 = Color(0xFFFFA07A); // Orange
  static const Color chart5 = Color(0xFF98D8C8); // Mint
  
  // Category colors (for transactions)
  static const Map<String, Color> categoryColors = {
    'Food': Color(0xFFFB923C),
    'Shopping': Color(0xFFEC4899),
    'Transportation': Color(0xFF8B5CF6),
    'Entertainment': Color(0xFF06B6D4),
    'Bills': Color(0xFFEAB308),
    'Healthcare': Color(0xFFF43F5E),
    'Education': Color(0xFF3B82F6),
    'Other': Color(0xFF6B7280),
    'Salary': Color(0xFF10B981),
    'Freelance': Color(0xFF14B8A6),
    'Investment': Color(0xFF8B5CF6),
  };
  
  // Neumorphic shadow colors
  static List<BoxShadow> neumorphicShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.8),
      blurRadius: 10,
      offset: const Offset(-4, -4),
    ),
  ];
  
  // Card shadow
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
  
  // Get category color
  static Color getCategoryColor(String category) {
    return categoryColors[category] ?? categoryColors['Other']!;
  }
  
  // Get color by hex string
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
  
  // Convert Color to hex string
  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }
}
