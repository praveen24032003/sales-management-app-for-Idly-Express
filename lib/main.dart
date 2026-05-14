import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/sales_provider.dart';
import 'providers/expense_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/dashboard_screen.dart';

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
      ],
      child: MaterialApp(
        title: 'Idly Express',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const DashboardScreen(),
      ),
    );
  }
}
