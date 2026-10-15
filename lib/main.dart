import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HolyNationApp());
}

class HolyNationApp extends StatelessWidget {
  const HolyNationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'THE HOLY NATION',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainNavigationScreen(),
    );
  }
}
