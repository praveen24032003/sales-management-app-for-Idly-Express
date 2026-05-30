import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/app_shell/application/app_session_controller.dart';
import 'features/app_shell/presentation/app_root.dart';
import 'features/settings/theme_controller.dart';
import 'features/workspace/application/workspace_data_controller.dart';

class IdlyExpressOrgApp extends StatelessWidget {
  const IdlyExpressOrgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()..load()),
        ChangeNotifierProvider(create: (_) => AppSessionController()..initialize()),
        ChangeNotifierProxyProvider<AppSessionController, WorkspaceDataController>(
          create: (_) => WorkspaceDataController(),
          update: (_, session, controller) => (controller ?? WorkspaceDataController())..bindSession(session),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: 'Idly Express Org Sync',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeController.mode,
            home: const AppRoot(),
          );
        },
      ),
    );
  }
}