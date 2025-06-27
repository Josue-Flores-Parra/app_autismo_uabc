import 'screens/login.dart';
import 'package:flutter/material.dart';
import '../strings/strings_utils.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.tituloAppBar,
      home: LoginScreen(),
    );
  }
}

