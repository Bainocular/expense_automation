import 'package:shared_preferences/shared_preferences.dart';

class PrefService {
  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  static Future<void> saveClient(String? client) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('client_name', client ?? "");
  }

  static Future<String?> getClient() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('client_name');
  }
}