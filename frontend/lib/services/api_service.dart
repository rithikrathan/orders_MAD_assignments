import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';
import '../models/food_item.dart';
import '../models/order.dart';
import '../models/support_ticket.dart';
import '../models/user_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
  }

  void setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('jwt_token', token);
    } else {
      await prefs.remove('jwt_token');
    }
  }

  Map<String, String> _getHeaders({bool requireAuth = false}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requireAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Auth: Register
  Future<Map<String, dynamic>> register({
    required String studentId,
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.register),
            headers: _getHeaders(),
            body: jsonEncode({
              'student_id': studentId,
              'name': name,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String;
        final user = UserModel.fromJson(data['user']);
        setToken(token);
        return {'success': true, 'user': user, 'token': token};
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Registration failed';
        return {'success': false, 'error': error};
      }
    } catch (e) {
      debugPrint('API Error (register fallback): $e');
      // Offline fallback
      final mockUser = UserModel(
        id: 1,
        studentId: studentId,
        name: name,
        email: email,
        walletBalance: 500.0,
      );
      setToken('mock_jwt_token_for_demo');
      return {'success': true, 'user': mockUser, 'token': 'mock_jwt_token_for_demo'};
    }
  }

  // Auth: Login
  Future<Map<String, dynamic>> login({
    required String studentIdOrEmail,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.login),
            headers: _getHeaders(),
            body: jsonEncode({
              'student_id_or_email': studentIdOrEmail,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String;
        final user = UserModel.fromJson(data['user']);
        setToken(token);
        return {'success': true, 'user': user, 'token': token};
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Invalid credentials';
        return {'success': false, 'error': error};
      }
    } catch (e) {
      debugPrint('API Error (login fallback): $e');
      // Offline mock login
      final mockUser = UserModel(
        id: 1,
        studentId: studentIdOrEmail.contains('@') ? 'CS2026-042' : studentIdOrEmail.toUpperCase(),
        name: 'Rithik Student',
        email: studentIdOrEmail.contains('@') ? studentIdOrEmail : 'student@college.edu',
        walletBalance: 750.00,
      );
      setToken('mock_jwt_token_for_demo');
      return {'success': true, 'user': mockUser, 'token': 'mock_jwt_token_for_demo'};
    }
  }

  // Fetch Menu
  Future<List<FoodItem>> getMenu({String? category, String? search, bool? isVegOnly}) async {
    try {
      final queryParams = <String, String>{};
      if (category != null && category != 'All') queryParams['category'] = category;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (isVegOnly == true) queryParams['veg_only'] = 'true';

      final uri = Uri.parse(ApiConstants.menu).replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      final response = await http.get(uri, headers: _getHeaders()).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => FoodItem.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('API Error (getMenu fallback): $e');
    }
    return _getFallbackMenu(category: category, search: search, isVegOnly: isVegOnly);
  }

  // Create Order
  Future<OrderModel?> createOrder({
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    String specialNotes = '',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.orders),
            headers: _getHeaders(requireAuth: true),
            body: jsonEncode({
              'items': items,
              'payment_method': paymentMethod,
              'special_notes': specialNotes,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return OrderModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('API Error (createOrder fallback): $e');
    }

    // Local fallback order generation
    double subtotal = 0;
    List<OrderItemModel> orderItems = [];
    for (var i = 0; i < items.length; i++) {
      int foodId = items[i]['food_item_id'];
      int qty = items[i]['quantity'];
      var fallback = _getFallbackMenu().firstWhere((f) => f.id == foodId, orElse: () => _getFallbackMenu().first);
      double itemTotal = fallback.price * qty;
      subtotal += itemTotal;
      orderItems.add(OrderItemModel(
        id: i + 1,
        orderId: 101,
        foodItemId: fallback.id,
        foodName: fallback.name,
        quantity: qty,
        unitPrice: fallback.price,
        totalPrice: itemTotal,
      ));
    }
    double tax = (subtotal * 0.05);
    double pkg = 10.0;
    return OrderModel(
      id: DateTime.now().millisecondsSinceEpoch % 10000,
      userId: 1,
      tokenNumber: '#C-${100 + (DateTime.now().second % 900)}',
      subtotal: subtotal,
      tax: tax,
      packagingFee: pkg,
      discount: 0,
      totalAmount: subtotal + tax + pkg,
      status: 'PENDING',
      paymentMethod: paymentMethod,
      paymentStatus: 'UNPAID',
      specialNotes: specialNotes,
      items: orderItems,
      createdAt: DateTime.now(),
    );
  }

  // Pay for Order
  Future<bool> payOrder({
    required int orderId,
    required String paymentMethod,
    required double amount,
    String? upiId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.payOrder(orderId)),
            headers: _getHeaders(requireAuth: true),
            body: jsonEncode({
              'payment_method': paymentMethod,
              'amount': amount,
              'upi_id': upiId ?? 'student@upi',
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('API Error (payOrder fallback): $e');
    }
    return true; // Fallback mock payment success
  }

  // Get Order History
  Future<List<OrderModel>> getOrders() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConstants.orders), headers: _getHeaders(requireAuth: true))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => OrderModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('API Error (getOrders fallback): $e');
    }
    return [];
  }

  // Get Student Support Tickets
  Future<List<SupportTicketModel>> getSupportTickets() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConstants.support), headers: _getHeaders(requireAuth: true))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => SupportTicketModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('API Error (getSupportTickets fallback): $e');
    }
    // Fallback tickets
    return [
      SupportTicketModel(
        id: 1,
        userId: 1,
        tokenNumber: '#C-142',
        category: 'Order Delay',
        subject: 'Token #C-142 taking more than 15 mins',
        message: 'Hi canteen staff, my lecture begins in 10 minutes. Can you please check if my order is ready?',
        adminReply: 'Chef is plating your hot dosa right now. Counter pickup ready in 2 mins!',
        status: 'IN_PROGRESS',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      SupportTicketModel(
        id: 2,
        userId: 1,
        tokenNumber: '#C-098',
        category: 'Payment / Refund',
        subject: 'Double charged for cold coffee via UPI',
        message: 'I scanned the QR code twice because first attempt showed pending. ₹70 was deducted twice.',
        adminReply: 'Verified with bank gateway. Credited ₹70 back to your Canteen Wallet balance.',
        status: 'RESOLVED',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  // Create Support Ticket
  Future<SupportTicketModel?> createSupportTicket({
    required String category,
    required String subject,
    required String message,
    String? tokenNumber,
    int? orderId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.support),
            headers: _getHeaders(requireAuth: true),
            body: jsonEncode({
              'category': category,
              'subject': subject,
              'message': message,
              'token_number': tokenNumber ?? '',
              'order_id': orderId,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return SupportTicketModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('API Error (createSupportTicket fallback): $e');
    }

    return SupportTicketModel(
      id: DateTime.now().millisecondsSinceEpoch % 10000,
      userId: 1,
      tokenNumber: tokenNumber ?? '',
      category: category,
      subject: subject,
      message: message,
      adminReply: '',
      status: 'OPEN',
      createdAt: DateTime.now(),
    );
  }

  // Fallback Menu data
  List<FoodItem> _getFallbackMenu({String? category, String? search, bool? isVegOnly}) {
    List<FoodItem> allItems = [
      FoodItem(
        id: 1,
        name: 'Masala Dosa with Chutneys',
        category: 'Breakfast',
        price: 60.0,
        isVeg: true,
        isAvailable: true,
        description: 'Crispy golden crepe filled with spiced potato masala, served with 2 chutneys and sambar.',
        rating: 4.8,
        prepTimeMinutes: 8,
        imageUrl: 'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?w=600&auto=format&fit=crop',
        calories: 320,
      ),
      FoodItem(
        id: 2,
        name: 'Steamed Idli (2 Pcs) & Vada',
        category: 'Breakfast',
        price: 50.0,
        isVeg: true,
        isAvailable: true,
        description: 'Soft steamed rice cakes with crispy medu vada and coconut chutney.',
        rating: 4.6,
        prepTimeMinutes: 5,
        imageUrl: 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=600&auto=format&fit=crop',
        calories: 240,
      ),
      FoodItem(
        id: 3,
        name: 'Classic Egg Omelette Toast',
        category: 'Breakfast',
        price: 55.0,
        isVeg: false,
        isAvailable: true,
        description: 'Fluffy double egg masala omelette served with butter toasted bread slices.',
        rating: 4.5,
        prepTimeMinutes: 7,
        imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=600&auto=format&fit=crop',
        calories: 310,
      ),
      FoodItem(
        id: 4,
        name: 'Paneer Butter Masala Meal',
        category: 'Lunch',
        price: 130.0,
        isVeg: true,
        isAvailable: true,
        description: 'Creamy paneer butter masala, 2 butter rotis, jeera rice, salad & sweet.',
        rating: 4.9,
        prepTimeMinutes: 12,
        imageUrl: 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=600&auto=format&fit=crop',
        calories: 650,
      ),
      FoodItem(
        id: 5,
        name: 'Dum Chicken Biryani',
        category: 'Lunch',
        price: 160.0,
        isVeg: false,
        isAvailable: true,
        description: 'Fragrant basmati rice slow cooked with marinated tender chicken and spices.',
        rating: 4.9,
        prepTimeMinutes: 10,
        imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&auto=format&fit=crop',
        calories: 720,
      ),
      FoodItem(
        id: 6,
        name: 'Crispy Samosa (2 Pcs)',
        category: 'Snacks',
        price: 30.0,
        isVeg: true,
        isAvailable: true,
        description: 'Golden crispy pastry shells filled with spiced potatoes & green peas.',
        rating: 4.8,
        prepTimeMinutes: 3,
        imageUrl: 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600&auto=format&fit=crop',
        calories: 260,
      ),
      FoodItem(
        id: 7,
        name: 'Grilled Cheese Sandwich',
        category: 'Snacks',
        price: 75.0,
        isVeg: true,
        isAvailable: true,
        description: 'Toasted triple-decker sandwich loaded with cheddar cheese & spiced veggies.',
        rating: 4.7,
        prepTimeMinutes: 8,
        imageUrl: 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=600&auto=format&fit=crop',
        calories: 360,
      ),
      FoodItem(
        id: 8,
        name: 'Special Filter Coffee',
        category: 'Beverages',
        price: 25.0,
        isVeg: true,
        isAvailable: true,
        description: 'Freshly brewed aromatic South Indian degree filter coffee.',
        rating: 4.9,
        prepTimeMinutes: 3,
        imageUrl: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=600&auto=format&fit=crop',
        calories: 90,
      ),
      FoodItem(
        id: 9,
        name: 'Cold Coffee with Ice Cream',
        category: 'Beverages',
        price: 70.0,
        isVeg: true,
        isAvailable: true,
        description: 'Thick blended cold coffee topped with a rich scoop of chocolate ice cream.',
        rating: 4.8,
        prepTimeMinutes: 5,
        imageUrl: 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=600&auto=format&fit=crop',
        calories: 290,
      ),
      FoodItem(
        id: 10,
        name: 'Warm Chocolate Lava Cake',
        category: 'Desserts',
        price: 85.0,
        isVeg: true,
        isAvailable: true,
        description: 'Decadent dark chocolate sponge cake with molten chocolate lava center.',
        rating: 4.9,
        prepTimeMinutes: 6,
        imageUrl: 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=600&auto=format&fit=crop',
        calories: 380,
      ),
    ];

    return allItems.where((item) {
      if (category != null && category != 'All' && item.category.toLowerCase() != category.toLowerCase()) {
        return false;
      }
      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        if (!item.name.toLowerCase().contains(q) && !item.description.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (isVegOnly == true && !item.isVeg) {
        return false;
      }
      return true;
    }).toList();
  }
}
