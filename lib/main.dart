import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/sales_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/theme_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'screens/add_entry_screen.dart';
import 'screens/external_order_form.dart';
import 'screens/dispatch_planner_screen.dart';
import 'screens/contacts_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const IdlyExpressApp());
}

class IdlyExpressApp extends StatelessWidget {
  const IdlyExpressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SalesProvider>(create: (context) => SalesProvider()),
        ChangeNotifierProvider<ExpenseProvider>(create: (context) => ExpenseProvider()),
        ChangeNotifierProvider<ThemeController>(create: (context) => ThemeController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: 'Idly Express',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeController.mode,
            home: const SplashScreen(),
            routes: {
              '/add-entry': (context) => const AddEntryScreen(),
              '/external-order': (context) => const ExternalOrderForm(),
              '/dispatch-planner': (context) => const DispatchPlannerScreen(),
              '/contacts': (context) => const ContactsScreen(),
            },
          );
        },
      ),
    );
  }
}
