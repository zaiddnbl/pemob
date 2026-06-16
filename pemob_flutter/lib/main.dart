import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SipeselApp());
}

class SipeselApp extends StatelessWidget {
  const SipeselApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIPESEL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        // ✅ SnackBar muncul dari atas
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
        // ✅ Dialog logout lebih rapi
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          titleTextStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A)),
          contentTextStyle: const TextStyle(
              fontSize: 14, color: Color(0xFF555555)),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}