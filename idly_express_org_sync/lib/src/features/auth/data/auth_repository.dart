import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';

class AuthRepository {
  static const mobileEmailRedirectTo = 'com.idlyexpress.salesmanager://login-callback/';

  Stream<AuthState> get authStateChanges => SupabaseConfig.client.auth.onAuthStateChange;

  User? get currentUser => SupabaseConfig.client.auth.currentUser;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await SupabaseConfig.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return SupabaseConfig.client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: kIsWeb ? null : mobileEmailRedirectTo,
    );
  }

  Future<void> signOut() async {
    await SupabaseConfig.client.auth.signOut();
  }
}