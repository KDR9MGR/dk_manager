import 'package:intl/intl.dart';

class AppUtils {
  static String formatPrice(double price) {
    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(price);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatQuantity(int quantity) {
    if (quantity == 0) {
      return 'Out of Stock';
    } else if (quantity < 5) {
      return 'Low Stock ($quantity)';
    }
    return '$quantity in Stock';
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  static String getInitials(String name) {
    if (name.isEmpty) return '';
    
    final names = name.split(' ');
    if (names.length == 1) {
      return names[0][0].toUpperCase();
    }
    
    return (names[0][0] + names[names.length - 1][0]).toUpperCase();
  }
} 