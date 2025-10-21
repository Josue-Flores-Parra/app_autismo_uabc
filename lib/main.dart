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

// Learning Module
import 'features/learning_module/view/module_list_screen.dart';
import 'features/learning_module/viewmodel/module_list_viewmodel.dart';

// Level Timeline
import 'features/learning_module/view/level_timeline_screen.dart';
import 'features/learning_module/viewmodel/level_timeline_viewmodel.dart';

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
      backgroundActual:
          'assets/images/Skins/DefaultSkin/backgrounds/default.jpg',
      monedas: 150, // Monedas iniciales
      accesoriosDesbloqueados: {
        'Antenitas', // Desbloqueado por defecto
        'Gafas', // Desbloqueado por defecto
      },
    );

    const String moduleId = 'Higiene_01';

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => AvatarViewModel(estadoInicial)),
        ChangeNotifierProvider(create: (_) => ModuleListViewModel()),
        ChangeNotifierProvider(create: (_) => LevelTimelineViewModel(moduleId)),
      ],
      child: MaterialApp(
        title: 'App Autismo UABC',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5B8DB3),
          ),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
        // home: const ModuleListScreen(),
        // home: const AvatarScreen(),
        // home: LevelTimelineScreen(
        //   moduleId: moduleId,
        //   backgroundImagePath:
        //       'assets/images/LevelBGs/Higiene/HigieneModuloBG.png',
        // ),
      ),
    );
  }
}
