import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/api_service.dart';

class MenuProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<FoodItem> _menuItems = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isVegOnly = false;
  bool _isLoading = false;

  final List<String> _categories = [
    'All',
    'Breakfast',
    'Lunch',
    'Snacks',
    'Beverages',
    'Desserts',
  ];

  List<FoodItem> get menuItems => _menuItems;
  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isVegOnly => _isVegOnly;
  bool get isLoading => _isLoading;

  MenuProvider() {
    fetchMenu();
  }

  Future<void> fetchMenu() async {
    _isLoading = true;
    notifyListeners();

    _menuItems = await _api.getMenu(
      category: _selectedCategory == 'All' ? null : _selectedCategory,
      search: _searchQuery.isEmpty ? null : _searchQuery,
      isVegOnly: _isVegOnly ? true : null,
    );

    _isLoading = false;
    notifyListeners();
  }

  void selectCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      fetchMenu();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchMenu();
  }

  void toggleVegOnly() {
    _isVegOnly = !_isVegOnly;
    fetchMenu();
  }
}
