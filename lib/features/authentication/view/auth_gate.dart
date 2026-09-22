import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/auth_viewmodel.dart';
import '../../../features/home/view/main_shell.dart';
import '../../legal/view/legal_consent_screen.dart';
import '../../legal/viewmodel/legal_viewmodel.dart';
import '../../onboarding/data/onboarding_service.dart';
import '../../onboarding/view/onboarding_screen.dart';
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

  // null mientras se consulta; después, si el dispositivo ya vio la
  // bienvenida. Se muestra antes del login, así que va por dispositivo.
  bool? _onboardingSeen;

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
    OnboardingService.hasSeen().then((seen) {
      if (!mounted) return;
      setState(() => _onboardingSeen = seen);
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
        // 2) Sin usuario (sesión cerrada o nunca iniciada): bienvenida la
        //    primera vez, después LoginScreen.
        if (authViewModel.currentUser == null) {
          if (_onboardingSeen == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (!_onboardingSeen!) {
            return OnboardingScreen(
              onFinished: () {
                if (!mounted) return;
                setState(() => _onboardingSeen = true);
              },
            );
          }
          return const LoginScreen();
        }
        // 3) Usuario presente: antes de la app, la aceptación de los
        //    documentos legales vigentes.
        return const _LegalGate();
      },
    );
  }
}

/// Decide entre la pantalla de consentimiento y la app.
///
/// Va después de [AuthGate] porque la versión aceptada se guarda por cuenta y
/// solo puede consultarse cuando ya hay sesión.
class _LegalGate extends StatefulWidget {
  const _LegalGate();

  @override
  State<_LegalGate> createState() => _LegalGateState();
}

class _LegalGateState extends State<_LegalGate> {
  void _ensureChecked() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LegalViewModel>().ensureChecked();
    });
  }

  @override
  void initState() {
    super.initState();
    _ensureChecked();
  }

  @override
  Widget build(BuildContext context) {
    final legal = context.watch<LegalViewModel>();

    switch (legal.status) {
      case LegalStatus.aceptado:
        return const MainShell();
      case LegalStatus.requiereAceptacion:
        return const LegalConsentScreen();
      case LegalStatus.desconocido:
        // Estado inicial o posterior a un cambio de cuenta: volver a consultar.
        _ensureChecked();
        return const _LegalLoading();
      case LegalStatus.cargando:
        return const _LegalLoading();
    }
  }
}

class _LegalLoading extends StatelessWidget {
  const _LegalLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
