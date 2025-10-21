import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Firebase
import 'firebase_options.dart';

// Auth
import 'features/authentication/viewmodel/auth_viewmodel.dart';
import 'features/authentication/view/login_screen.dart';

// Avatar
import 'features/avatar/model/avatar_models.dart';
import 'features/avatar/data/avatar_repository.dart';
import 'features/avatar/viewmodel/avatar_viewmodel.dart';
import 'features/avatar/view/avatar_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener skins disponibles del repositorio
    final skinsDisponibles = AvatarRepository.obtenerSkinsDisponibles();

    // Crear el estado inicial del avatar
    final estadoInicial = AvatarEstado(
      nombre: 'MRBEAST',
      felicidad: 66,
      energia: 92,
      skinActual: skinsDisponibles.first,
      backgroundActual: 'assets/images/Skins/DefaultSkin/backgrounds/default.jpg',
      monedas: 150, // Monedas iniciales
      accesoriosDesbloqueados: {
        'Antenitas', // Desbloqueado por defecto
        'Gafas', // Desbloqueado por defecto
      },
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => AvatarViewModel(estadoInicial)),
      ],
      child: MaterialApp(
        title: 'App Autismo UABC',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B8DB3)),
          useMaterial3: true,
        ),
        home: const LoginScreen(), // o AvatarScreen() según el flujo que desees
      ),
    );
  }
}
