import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static bool _isReady = false;

  static bool get isReady => _isReady;

  static void markReady() {
    _isReady = true;
  }

  static void markUnavailable() {
    _isReady = false;
  }

  static SupabaseClient get client => Supabase.instance.client;
}