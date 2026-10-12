class OrderModel {
  final int id;
  final int userId;
  final String tokenNumber;
  final double subtotal;
  final double tax;
  final double packagingFee;
  final double discount;
  final double totalAmount;
  final String status; // PENDING, PAID, PREPARING, READY_FOR_PICKUP, COMPLETED, CANCELLED
  final String paymentMethod;
  final String paymentStatus;
  final String specialNotes;
  final List<OrderItemModel> items;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.tokenNumber,
    required this.subtotal,
    required this.tax,
    required this.packagingFee,
    required this.discount,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.specialNotes,
    required this.items,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List<dynamic>? ?? [];
    List<OrderItemModel> parsedItems = rawItems
        .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return OrderModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      tokenNumber: json['token_number'] as String? ?? '#C-000',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      packagingFee: (json['packaging_fee'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'PENDING',
      paymentMethod: json['payment_method'] as String? ?? 'UPI',
      paymentStatus: json['payment_status'] as String? ?? 'UNPAID',
      specialNotes: json['special_notes'] as String? ?? '',
      items: parsedItems,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class OrderItemModel {
  final int id;
  final int orderId;
  final int foodItemId;
  final String foodName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.foodItemId,
    required this.foodName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as int? ?? 0,
      orderId: json['order_id'] as int? ?? 0,
      foodItemId: json['food_item_id'] as int? ?? 0,
      foodName: json['food_name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
