import 'dart:async';
import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<OrderModel> _orders = [];
  OrderModel? _currentActiveOrder;
  bool _isPlacingOrder = false;
  bool _isProcessingPayment = false;
  String? _errorMessage;

  List<OrderModel> get orders => _orders;
  OrderModel? get currentActiveOrder => _currentActiveOrder;
  bool get isPlacingOrder => _isPlacingOrder;
  bool get isProcessingPayment => _isProcessingPayment;
  String? get errorMessage => _errorMessage;

  OrderProvider() {
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    _orders = await _api.getOrders();
    if (_orders.isNotEmpty) {
      // Find latest pending or preparing order
      _currentActiveOrder = _orders.firstWhere(
        (o) => o.status != 'COMPLETED' && o.status != 'CANCELLED',
        orElse: () => _orders.first,
      );
    }
    notifyListeners();
  }

  Future<OrderModel?> placeOrder({
    required List<CartItem> cartItems,
    required String paymentMethod,
    String specialNotes = '',
  }) async {
    _isPlacingOrder = true;
    _errorMessage = null;
    notifyListeners();

    final itemsPayload = cartItems
        .map((item) => {
              'food_item_id': item.foodItem.id,
              'quantity': item.quantity,
            })
        .toList();

    final order = await _api.createOrder(
      items: itemsPayload,
      paymentMethod: paymentMethod,
      specialNotes: specialNotes,
    );

    _isPlacingOrder = false;
    if (order != null) {
      _currentActiveOrder = order;
      _orders.insert(0, order);
      notifyListeners();
      return order;
    } else {
      _errorMessage = 'Failed to place order';
      notifyListeners();
      return null;
    }
  }

  Future<bool> payForOrder({
    required int orderId,
    required String paymentMethod,
    required double amount,
    String? upiId,
  }) async {
    _isProcessingPayment = true;
    notifyListeners();

    // Simulate realistic network delay for payment gateway
    await Future.delayed(const Duration(milliseconds: 1500));

    final success = await _api.payOrder(
      orderId: orderId,
      paymentMethod: paymentMethod,
      amount: amount,
      upiId: upiId,
    );

    _isProcessingPayment = false;
    if (success) {
      // Update local state to PREPARING
      if (_currentActiveOrder != null && _currentActiveOrder!.id == orderId) {
        _currentActiveOrder = OrderModel(
          id: _currentActiveOrder!.id,
          userId: _currentActiveOrder!.userId,
          tokenNumber: _currentActiveOrder!.tokenNumber,
          subtotal: _currentActiveOrder!.subtotal,
          tax: _currentActiveOrder!.tax,
          packagingFee: _currentActiveOrder!.packagingFee,
          discount: _currentActiveOrder!.discount,
          totalAmount: _currentActiveOrder!.totalAmount,
          status: 'PREPARING',
          paymentMethod: paymentMethod,
          paymentStatus: 'PAID',
          specialNotes: _currentActiveOrder!.specialNotes,
          items: _currentActiveOrder!.items,
          createdAt: _currentActiveOrder!.createdAt,
        );
      }
      notifyListeners();
      _startStatusTimer();
      return true;
    }
    return false;
  }

  void _startStatusTimer() {
    // Auto-advance status after 8 seconds to READY_FOR_PICKUP for demo
    Timer(const Duration(seconds: 8), () {
      if (_currentActiveOrder != null && _currentActiveOrder!.status == 'PREPARING') {
        _currentActiveOrder = OrderModel(
          id: _currentActiveOrder!.id,
          userId: _currentActiveOrder!.userId,
          tokenNumber: _currentActiveOrder!.tokenNumber,
          subtotal: _currentActiveOrder!.subtotal,
          tax: _currentActiveOrder!.tax,
          packagingFee: _currentActiveOrder!.packagingFee,
          discount: _currentActiveOrder!.discount,
          totalAmount: _currentActiveOrder!.totalAmount,
          status: 'READY_FOR_PICKUP',
          paymentMethod: _currentActiveOrder!.paymentMethod,
          paymentStatus: 'PAID',
          specialNotes: _currentActiveOrder!.specialNotes,
          items: _currentActiveOrder!.items,
          createdAt: _currentActiveOrder!.createdAt,
        );
        notifyListeners();
      }
    });
  }

  void markOrderCompleted() {
    if (_currentActiveOrder != null) {
      _currentActiveOrder = OrderModel(
        id: _currentActiveOrder!.id,
        userId: _currentActiveOrder!.userId,
        tokenNumber: _currentActiveOrder!.tokenNumber,
        subtotal: _currentActiveOrder!.subtotal,
        tax: _currentActiveOrder!.tax,
        packagingFee: _currentActiveOrder!.packagingFee,
        discount: _currentActiveOrder!.discount,
        totalAmount: _currentActiveOrder!.totalAmount,
        status: 'COMPLETED',
        paymentMethod: _currentActiveOrder!.paymentMethod,
        paymentStatus: 'PAID',
        specialNotes: _currentActiveOrder!.specialNotes,
        items: _currentActiveOrder!.items,
        createdAt: _currentActiveOrder!.createdAt,
      );
      notifyListeners();
    }
  }
}
