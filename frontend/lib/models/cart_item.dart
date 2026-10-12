import 'food_item.dart';

class CartItem {
  final FoodItem foodItem;
  int quantity;
  final String specialInstruction;

  CartItem({
    required this.foodItem,
    this.quantity = 1,
    this.specialInstruction = '',
  });

  double get totalPrice => foodItem.price * quantity;

  CartItem copyWith({
    FoodItem? foodItem,
    int? quantity,
    String? specialInstruction,
  }) {
    return CartItem(
      foodItem: foodItem ?? this.foodItem,
      quantity: quantity ?? this.quantity,
      specialInstruction: specialInstruction ?? this.specialInstruction,
    );
  }
}
