import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/inventory_provider.dart';
import 'screens/dashboard_screen.dart';
import 'services/database_service.dart';
import 'theme/app_theme.dart';
import 'screens/pin_lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialize Hive database
  await DatabaseService.initialize();

  runApp(const BoxwiseApp());
}

class BoxwiseApp extends StatelessWidget {
  const BoxwiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InventoryProvider()..loadBoxes(),
      child: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: 'Boxwise - Smart Inventory',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const PinLockScreen(child: DashboardScreen()),
          );
        },
      ),
    );
  }
}
