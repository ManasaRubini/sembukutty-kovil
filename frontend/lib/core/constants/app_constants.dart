import 'package:shared_preferences/shared_preferences.dart';

class AppConstants {
  // SharedPreferences keys
  static const kApiBaseUrl = 'api_base_url';
  static const kCurrentStaffId = 'current_staff_id';
  static const kAuthToken = 'auth_token';

  // Default API URL — set to live Cloudflare Tunnel
  static const defaultApiUrl = 'https://isle-spaces-project-disabilities.trycloudflare.com';

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
    _baseUrl = prefs.getString(AppConstants.kApiBaseUrl) ?? AppConstants.defaultApiUrl;
  }

  static Future<void> save(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.kApiBaseUrl, url);
    _baseUrl = url;
  }
}
