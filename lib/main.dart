import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/usuario.dart';
import 'views/login.dart';
import '../resources/strings_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(UsuarioAdapter());
  await Hive.openBox<Usuario>(AppStrings.usuario);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.tituloAppBar,
      home: const LoginScreen(),
    );
  }
}
