import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/offline/hive_cache.dart';
import '../services/offline/offline_repository.dart';
import '../services/push_notification_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _loading = true;
  SharedPreferences? _prefs;

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
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs!.getString('authUser');
    if (stored != null) {
      _user = jsonDecode(stored);
      ApiService.setToken(_user?['token']);
      // Background prefetch for instant screens
      OfflineRepository.prefetchForUser(_user!);
      // Register device for push notifications
      PushNotificationService.registerDevice();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> login(Map<String, dynamic> userData) async {
    final oldBranchId = _user?['branch_id'];
    final newBranchId = userData['branch_id'];
    _user = userData;
    ApiService.setToken(userData['token']);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString('authUser', jsonEncode(userData));

    // Branch changed — nuke stale cache so screens don't flash old data
    if (oldBranchId != null && newBranchId != null && oldBranchId != newBranchId) {
      await HiveCache.clearAll();
    }

    notifyListeners();
    // Register device for push notifications
    PushNotificationService.registerDevice();
    // Prefetch all data — await on branch switch so cache is warm before screens load
    if (oldBranchId != null && newBranchId != null && oldBranchId != newBranchId) {
      await OfflineRepository.prefetchForUser(userData);
    } else {
      OfflineRepository.prefetchForUser(userData);
    }
  }

  Future<void> logout() async {
    _user = null;
    ApiService.clearToken();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove('authUser');
    await _prefs!.remove('headCoachMode');
    await HiveCache.clearAll();
    notifyListeners();
  }

  Future<void> refreshUser() async {
    _prefs ??= await SharedPreferences.getInstance();
    final stored = _prefs!.getString('authUser');
    if (stored != null) {
      _user = jsonDecode(stored);
      ApiService.setToken(_user?['token']);
      notifyListeners();
    }
  }

  /// Check with the server if the user has been approved.
  /// Returns true if status changed to approved.
  Future<bool> checkApproval() async {
    if (_user == null || isApproved) return false;
    try {
      final resp = await ApiService().get('/auth/me');
      if (resp.data != null && resp.data['approved'] == true) {
        _user!['isApproved'] = true;
        _prefs ??= await SharedPreferences.getInstance();
        await _prefs!.setString('authUser', jsonEncode(_user));
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> setHeadCoachMode(bool value) async {
    _prefs ??= await SharedPreferences.getInstance();
    if (value) {
      await _prefs!.setString('headCoachMode', 'true');
    } else {
      await _prefs!.remove('headCoachMode');
    }
  }
}
