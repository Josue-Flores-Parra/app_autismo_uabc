import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/avatar/model/avatar_models.dart';
import 'features/avatar/data/avatar_repository.dart';
import 'features/avatar/viewmodel/avatar_viewmodel.dart';
import 'features/avatar/view/avatar_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener skins disponibles del repositorio
    final skinsDisponibles =
        AvatarRepository.obtenerSkinsDisponibles();

    // Crear el estado inicial del avatar
    final estadoInicial = AvatarEstado(
      nombre: 'MRBEAST',
      felicidad: 66,
      energia: 92,
      skinActual:
          skinsDisponibles.first,
      backgroundActual:
          'assets/images/Skins/DefaultSkin/backgrounds/default.jpg',
      monedas: 150, // Monedas iniciales
      accesoriosDesbloqueados: {
        'Antenitas', // Desbloqueado por defecto
        'Gafas', // Desbloqueado por defecto
      },
    );

    return ChangeNotifierProvider(
      create: (_) => AvatarViewModel(
        estadoInicial,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner:
            false,
        home: const AvatarScreen(),
      ),
    );
  }
}
