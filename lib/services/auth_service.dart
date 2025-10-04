// Lightweight AuthService placeholder. Configure Firebase or Supabase as needed.
import 'package:flutter/foundation.dart';

class AuthService {
  static Future<void> initialize() async {
    // Initialize Firebase or Supabase here.
    // Example:
    // await Firebase.initializeApp();
    // await Supabase.initialize(url: 'YOUR_SUPABASE_URL', anonKey: 'YOUR_ANON_KEY');
    if (kDebugMode) {
      print('AuthService.initialize called - add your config');
    }
  }

  static Future<String?> currentUserId() async {
    // Return user id string if logged in. Placeholder for real auth integration.
    return null;
  }
}
