import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';

Future<void> bootstrap() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    await dotenv.load(fileName: '.env.example');
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  final hasPlaceholderKey =
      supabaseAnonKey.isEmpty || supabaseAnonKey.contains('PASTE_YOUR_SUPABASE_ANON_KEY_HERE');

  if (supabaseUrl.isEmpty || hasPlaceholderKey) {
    SupabaseConfig.markUnavailable();
    debugPrint('Supabase env values are placeholders. Replace them before running against a real backend.');
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  SupabaseConfig.markReady();
}