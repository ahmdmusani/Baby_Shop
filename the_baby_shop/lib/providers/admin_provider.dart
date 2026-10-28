import 'package:flutter/material.dart';
import '../models/admin_user_model.dart';
import '../repositories/admin_repository.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _repository = AdminRepository();

  List<AdminUserModel> _users = [];
  List<AdminUserModel> _filteredUsers = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<AdminUserModel> get users => _filteredUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<AdminUserModel>> get usersStream => _repository.getAllUsers();

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  void updateUserList(List<AdminUserModel> users) {
    _users = users;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredUsers = List.from(_users);
    } else {
      _filteredUsers = _users.where((u) {
        return u.fullName.toLowerCase().contains(_searchQuery) ||
            u.email.toLowerCase().contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> updateUserStatus(String uid, bool isDisabled) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.updateUserStatus(uid, isDisabled);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.deleteUser(uid);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.updateUserProfile(uid, data);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
