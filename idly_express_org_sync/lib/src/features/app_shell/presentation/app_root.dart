import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/brand_widgets.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../dashboard/presentation/workspace_shell_screen.dart';
import '../../organization/presentation/organization_gate_screen.dart';
import '../application/app_session_controller.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSessionController>();

    if (!SupabaseConfig.isReady) {
      return const _SupabaseSetupScreen();
    }

    if (session.isLoading) {
      return const _BrandLoadingScreen();
    }

    if (session.currentUser == null) {
      return const AuthScreen();
    }

    if (session.activeOrganization == null) {
      return const OrganizationGateScreen();
    }

    return const WorkspaceShellScreen();
  }
}

class _BrandLoadingScreen extends StatelessWidget {
  const _BrandLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: brand.surfaceTop,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: BrandTokens.scaffoldGradient(context)),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandWordmark(size: 28, showTagline: true),
                const SizedBox(height: 28),
                SizedBox(
                  height: 26,
                  width: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.6, color: colorScheme.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SupabaseSetupScreen extends StatelessWidget {
  const _SupabaseSetupScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    return Scaffold(
      backgroundColor: brand.surfaceTop,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: BrandTokens.scaffoldGradient(context)),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: BrandCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 52,
                            width: 52,
                            decoration: BoxDecoration(
                              color: brand.warningBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.cloud_off_rounded, color: brand.warningFg),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Supabase is not configured yet',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: brand.textStrong),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Add real SUPABASE_URL and SUPABASE_ANON_KEY values to the env file, then restart the app. Until then the org login and realtime workspace stay disabled.',
                        style: TextStyle(color: brand.textBody, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
