import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VocalisApp());
}

class VocalisApp extends StatelessWidget {
  const VocalisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocalis AI - Treino de Pronúncia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
