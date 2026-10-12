class FoodItem {
  final int id;
  final String name;
  final String category;
  final double price;
  final bool isVeg;
  final bool isAvailable;
  final String description;
  final double rating;
  final int prepTimeMinutes;
  final String imageUrl;
  final int calories;

  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.isVeg,
    required this.isAvailable,
    required this.description,
    required this.rating,
    required this.prepTimeMinutes,
    required this.imageUrl,
    required this.calories,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isVeg: json['is_veg'] as bool? ?? true,
      isAvailable: json['is_available'] as bool? ?? true,
      description: json['description'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      prepTimeMinutes: json['prep_time_minutes'] as int? ?? 10,
      imageUrl: json['image_url'] as String? ?? '',
      calories: json['calories'] as int? ?? 250,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'is_veg': isVeg,
      'is_available': isAvailable,
      'description': description,
      'rating': rating,
      'prep_time_minutes': prepTimeMinutes,
      'image_url': imageUrl,
      'calories': calories,
    };
  }
}
