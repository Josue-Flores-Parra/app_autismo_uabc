import 'package:app_autismo/strings/strings_utils.dart';
import 'package:flutter/material.dart';
import 'screens/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.tituloApp,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

