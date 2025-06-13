import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'strings/strings_utils.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.tituloApp,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}