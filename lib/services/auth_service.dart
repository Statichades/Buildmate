import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      try {
        final userJson = json.decode(userData);
        return User.fromJson(userJson);
      } catch (e) {
        await logout();
        return null;
      }
    }
    return null;
  }

  Future<void> setCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = json.encode(user.toJson());
    await prefs.setString(_userKey, userData);
    await prefs.setBool('isLoggedIn', true);
    await prefs.setInt('user_id', user.id);
  }

  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  Future<User?> login(String email, String password) async {
    try {
      final response = await ApiService().post(
        '/users/login',
        body: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final userJson = json.decode(response.body);

        final user = User.fromJson(userJson);
        debugPrint('Login Response: $user');
        await setCurrentUser(user);
        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await ApiService().post(
        '/users',
        body: {'name': name, 'email': email, 'password': password},
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {'success': true, 'user_id': data['id']};
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  Future<bool> sendVerificationEmail(String email) async {
    try {
      final response = await ApiService().post(
        '/users/send-verification',
        body: {'email': email},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> verifyEmail(String email, String code) async {
    try {
      final response = await ApiService().post(
        '/users/verify-email',
        body: {'email': email, 'verification_code': code},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProfile(int userId, Map<String, dynamic> updates) async {
    try {
      final response = await ApiService().patch(
        '/users/$userId',
        body: updates,
      );
      if (response.statusCode == 200) {
        final currentUser = await getCurrentUser();
        if (currentUser != null && currentUser.id == userId) {
          final updatedUser = currentUser.copyWith(
            name: updates['name'],
            email: updates['email'],
            mobileNumber: updates['mobile_number'],
            profileUrl: updates['profile_url'],
            deleteUrl: updates['delete_url'],
          );
          await setCurrentUser(updatedUser);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }

  Future<int?> getUserId() async {
    final user = await getCurrentUser();
    return user?.id;
  }
}
