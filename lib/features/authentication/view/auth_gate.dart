import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/auth_viewmodel.dart';
import '../../../features/home/view/main_shell.dart';
import 'login_screen.dart';

/// Widget raíz que decide qué pantalla mostrar según el estado de autenticación.
///
/// Acts como una "puerta" (gate): escucha los cambios de [AuthViewModel] a
/// través de un [Consumer] y, ante cualquier modificación de
/// `currentUser` (login, logout, eliminación de cuenta), reconstruye
/// automáticamente y swaps entre [LoginScreen] y [MainShell].
///
/// Esto reemplaza la navegación imperativa anterior ( Navigator
/// .pushReplacement / pushAndRemoveUntil ) por un enfoque reactivo basado en
/// el árbol de widgets.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Flag que indica si ya pasó el primer frame tras el arranque.
  // En móvil `currentUser` se restaura sincrónicamente desde FirebaseAuth
  // durante `main()`, pero este flag sirve como red de seguridad para web y
  // para evitar un destello (flash) de pantalla en el primer render.
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    // Espera al primer post-frame callback antes de considerar la app lista.
    // Garantiza que el árbol de widgets (y los Providers) estén montados antes
    // de leer `currentUser` y decidir la pantalla inicial.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _isReady = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // El Consumer escucha a AuthViewModel; cada `notifyListeners()` (login,
    // logout, deleteAccount) dispara un rebuild de este builder y, por ende,
    // el swap automático entre LoginScreen y MainShell.
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        // 1) Splash inicial: mostramos un indicador de carga centrado hasta
        //    que se complete el primer post-frame callback.
        if (!_isReady) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // 2) Sin usuario (sesión cerrada o nunca iniciada): LoginScreen.
        if (authViewModel.currentUser == null) {
          return const LoginScreen();
        }
        // 3) Usuario presente (login exitoso o sesión restaurada): MainShell.
        return const MainShell();
      },
    );
  }
}