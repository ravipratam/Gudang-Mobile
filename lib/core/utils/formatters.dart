import 'package:intl/intl.dart';

class Formatters {
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
  static final NumberFormat _numberFormat = NumberFormat('#,###', 'id_ID');

  static String formatDateTime(DateTime dateTime) {
    try {
      return _dateTimeFormat.format(dateTime.toLocal());
    } catch (_) {
      return dateTime.toLocal().toString().substring(0, 16);
    }
  }

  static String formatDate(DateTime dateTime) {
    try {
      return _dateFormat.format(dateTime.toLocal());
    } catch (_) {
      return dateTime.toLocal().toString().substring(0, 10);
    }
  }

  static String formatNumber(int number) {
    return _numberFormat.format(number);
  }

  static String generateSku(String categoryPrefix) {
    final cleanPrefix = categoryPrefix.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    final prefix = cleanPrefix.length >= 3 ? cleanPrefix.substring(0, 3) : (cleanPrefix.padRight(3, 'X'));
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    return '$prefix-$timestamp';
  }
}
