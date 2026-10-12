import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null || _token != null;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    await _api.init();
    // Default demo student user if not logged in
    _user = UserModel(
      id: 1,
      studentId: 'CS2026-042',
      name: 'Rithik Student',
      email: 'rithik@college.edu',
      walletBalance: 750.00,
    );
    notifyListeners();
  }

  Future<bool> login(String studentIdOrEmail, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _api.login(
      studentIdOrEmail: studentIdOrEmail,
      password: password,
    );

    _isLoading = false;
    if (result['success'] == true) {
      _user = result['user'];
      _token = result['token'];
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['error'] ?? 'Login failed';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String studentId,
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _api.register(
      studentId: studentId,
      name: name,
      email: email,
      password: password,
    );

    _isLoading = false;
    if (result['success'] == true) {
      _user = result['user'];
      _token = result['token'];
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['error'] ?? 'Registration failed';
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _user = null;
    _token = null;
    _api.setToken(null);
    notifyListeners();
  }
}
