import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _loading = true;

  Map<String, dynamic>? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user?['isLoggedIn'] == true;
  bool get isApproved => _user?['isApproved'] == true;
  String? get role => _user?['role'];
  String? get token => _user?['token'];
  int? get branchId => _user?['branch_id'];
  int? get userId => _user?['id'];
  String? get userName => _user?['name'];
  String? get userEmail => _user?['email'];

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('authUser');
      if (stored != null) {
        _user = jsonDecode(stored);
      }
    } catch (e) {
      debugPrint('Failed to load user: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> login(Map<String, dynamic> userData) async {
    _user = userData;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authUser', jsonEncode(userData));
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authUser');
    await prefs.remove('headCoachMode');
    notifyListeners();
  }

  Future<void> refreshUser() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('authUser');
    if (stored != null) {
      _user = jsonDecode(stored);
      notifyListeners();
    }
  }

  Future<bool> isHeadCoachMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('headCoachMode') == 'true';
  }

  Future<void> setHeadCoachMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setString('headCoachMode', 'true');
    } else {
      await prefs.remove('headCoachMode');
    }
  }
}
