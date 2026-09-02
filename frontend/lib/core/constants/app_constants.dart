import 'package:shared_preferences/shared_preferences.dart';

class AppConstants {
  // SharedPreferences keys
  static const kApiBaseUrl = 'api_base_url';
  static const kCurrentStaffId = 'current_staff_id';
  static const kAuthToken = 'auth_token';
  static const kUserRole = 'user_role';
  static const kIsLoggedIn = 'is_logged_in';

  // Default API URL — 24/7 Render Cloud Server
  static const defaultApiUrl = 'https://sembukutty-kovil-api.onrender.com';

  // Max active billing staff
  static const maxStaff = 5;
}

class ApiConfig {
  static String _baseUrl = AppConstants.defaultApiUrl;

  static String get baseUrl => _baseUrl;

  static set baseUrl(String url) {
    _baseUrl = url;
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(AppConstants.kApiBaseUrl);
    
    // Auto-clear old expired trycloudflare / localhost URLs from phone memory
    if (savedUrl == null || savedUrl.contains('trycloudflare.com') || savedUrl.contains('localhost') || savedUrl.contains('127.0.0.1')) {
      _baseUrl = AppConstants.defaultApiUrl;
      await prefs.setString(AppConstants.kApiBaseUrl, AppConstants.defaultApiUrl);
    } else {
      _baseUrl = savedUrl;
    }
  }

  static Future<void> save(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.kApiBaseUrl, url);
    _baseUrl = url;
  }
}
