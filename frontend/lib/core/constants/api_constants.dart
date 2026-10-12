import 'package:flutter/foundation.dart';

class ApiConstants {
  // Base URL:
  // For web or linux desktop: http://localhost:8080/api
  // For Android emulator (if used in future): http://10.0.2.2:8080/api
  static String get baseUrl {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.windows) {
      return 'http://localhost:8080/api';
    }
    return 'http://10.0.2.2:8080/api';
  }

  // Endpoints
  static String get register => '$baseUrl/auth/register';
  static String get login => '$baseUrl/auth/login';
  static String get profile => '$baseUrl/auth/me';
  
  static String get menu => '$baseUrl/menu';
  static String get categories => '$baseUrl/menu/categories';
  
  static String get orders => '$baseUrl/orders';
  static String orderById(int id) => '$baseUrl/orders/$id';
  static String payOrder(int id) => '$baseUrl/orders/$id/pay';
  static String updateOrderStatus(int id) => '$baseUrl/orders/$id/status';
  
  static String get support => '$baseUrl/support';
}
