import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/food_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _appliedCoupon;
  double _discountPercent = 0.0;
  String _orderNotes = '';

  List<CartItem> get items => _items;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;
  String? get appliedCoupon => _appliedCoupon;
  String get orderNotes => _orderNotes;

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get tax => double.parse((subtotal * 0.05).toStringAsFixed(2)); // 5% GST
  double get packagingFee => _items.isEmpty ? 0.0 : 10.0;
  double get discountAmount => double.parse((subtotal * _discountPercent).toStringAsFixed(2));
  double get grandTotal => _items.isEmpty ? 0.0 : double.parse((subtotal + tax + packagingFee - discountAmount).toStringAsFixed(2));

  int getItemQuantity(int foodItemId) {
    try {
      final cartItem = _items.firstWhere((item) => item.foodItem.id == foodItemId);
      return cartItem.quantity;
    } catch (_) {
      return 0;
    }
  }

  void addItem(FoodItem foodItem, {int quantity = 1, String specialInstruction = ''}) {
    final index = _items.indexWhere((item) => item.foodItem.id == foodItem.id);
    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(
        foodItem: foodItem,
        quantity: quantity,
        specialInstruction: specialInstruction,
      ));
    }
    notifyListeners();
  }

  void removeItem(FoodItem foodItem) {
    _items.removeWhere((item) => item.foodItem.id == foodItem.id);
    notifyListeners();
  }

  void updateQuantity(FoodItem foodItem, int newQuantity) {
    final index = _items.indexWhere((item) => item.foodItem.id == foodItem.id);
    if (index >= 0) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = newQuantity;
      }
      notifyListeners();
    }
  }

  void incrementItem(FoodItem foodItem) {
    final index = _items.indexWhere((item) => item.foodItem.id == foodItem.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      addItem(foodItem);
    }
    notifyListeners();
  }

  void decrementItem(FoodItem foodItem) {
    final index = _items.indexWhere((item) => item.foodItem.id == foodItem.id);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  bool applyCoupon(String code) {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode == 'CANTEEN20' || cleanCode == 'CAMPUS10' || cleanCode == 'MAD2026') {
      _appliedCoupon = cleanCode;
      _discountPercent = 0.15; // 15% discount
      notifyListeners();
      return true;
    }
    return false;
  }

  void removeCoupon() {
    _appliedCoupon = null;
    _discountPercent = 0.0;
    notifyListeners();
  }

  void setOrderNotes(String notes) {
    _orderNotes = notes;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _appliedCoupon = null;
    _discountPercent = 0.0;
    _orderNotes = '';
    notifyListeners();
  }
}
