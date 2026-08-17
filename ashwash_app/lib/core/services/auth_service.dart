import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../../data/models/user_model.dart';

class AuthService {
  // Uses central Base URL from ApiConfig
  static String get baseUrl => '${ApiConfig.baseUrl}/auth';

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  // --- LOGIN FUNCTION (Django REST API) ---
  Future<bool> login(String username, String password) async {
    final cleanUser = username.trim();
    final cleanPass = password.trim();

    if (cleanUser.isEmpty || cleanPass.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': cleanUser,
          'password': cleanPass,
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String accessToken = data['access'];
        final String refreshToken = data['refresh'];

        // Save JWT Tokens locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);

        // Fetch user profile from Django using the token
        await _fetchUserProfile(accessToken);
        return true;
      } else {
        try {
            final errorData = jsonDecode(response.body);
            print("Login Failed: ${response.statusCode} - ${errorData['detail'] ?? response.body}");
        } catch (_) {
            print("Login Failed: ${response.statusCode} - ${response.body}");
        }
        return false;
      }
    } catch (e) {
      if (e is FormatException) {
         print("Django Login Error: Invalid response format");
      } else {
         print("Django Login Error (Connection/Timeout): $e\nThis usually happens if the server is asleep (cold start). Try again in a minute.");
      }
      return false;
    }
  }

  // --- REGISTER FUNCTION (Django REST API) ---
  Future<bool> register(String username, String email, String password) async {
    final cleanUser = username.trim();
    final cleanEmail = email.trim();
    final cleanPass = password.trim();

    if (cleanUser.isEmpty || cleanPass.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': cleanUser,
          'email': cleanEmail,
          'password': cleanPass,
          'role': 'PATIENT',
        }),
      );

      if (response.statusCode == 201) {
        print("Registration Successful in MySQL!");
        // Auto login after registration
        return await login(cleanUser, cleanPass);
      } else {
        print("Registration Failed: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("Django Registration Error: $e");
      return false;
    }
  }

  // --- FETCH USER PROFILE FROM DJANGO ---
  Future<void> _fetchUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = UserModel(
          id: data['id'] ?? 1,
          username: data['username'] ?? '',
          email: data['email'] ?? '',
          firstName: data['username'] ?? '',
          lastName: '',
          totalPoints: 0,
          sessionsAttended: 0,
          tasksCompleted: 0,
        );
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }
}