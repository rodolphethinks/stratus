import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StratusApp());
}

class StratusApp extends StatelessWidget {
  const StratusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stratus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}


