import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appy/shared/widgets/custom_bottom_nav_bar.dart';
import 'package:appy/features/learning_module/view/module_list_screen.dart';
import 'package:appy/features/avatar/view/avatar_screen.dart';
import 'package:appy/features/settings/view/settings_page.dart';
import 'package:appy/features/settings/viewmodel/settings_viewmodel.dart';
import 'package:appy/shared/services/pin_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() {
    return _MainShellState();
  }
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  late Widget activeScreen;

  final List<Widget> screen = [
    const ModuleListScreen(),
    const AvatarScreen(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    activeScreen = screen[_selectedIndex];
  }

  Future<void> _onItemTapped(int index) async {
    // Si ya está en Ajustes y vuelve a tocar Ajustes, no pedir PIN de nuevo.
    if (index == 2 && _selectedIndex == 2) return;

    if (index == 2) {
      final unlocked = await _ensureSettingsAccess();
      if (!unlocked) return;
    }

    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
      activeScreen = screen[_selectedIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();
    final animationDuration =
        settings.reduceAnimations ? Duration.zero : const Duration(milliseconds: 600);
    final fadeCurve = settings.reduceAnimations ? Curves.linear : Curves.easeInOutCubic;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: animationDuration,
        transitionBuilder: (Widget child, Animation<double> animation) {
          if (settings.reduceAnimations) {
            return child;
          }
          return FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: fadeCurve,
            )),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.95,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            ),
          );
        },
        child: Container(
          key: ValueKey(_selectedIndex),
          child: activeScreen,
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Future<bool> _ensureSettingsAccess() async {
    final storedPin = await PinService.getPin();
    if (storedPin == null) {
      return _promptCreatePin();
    }
    return _promptEnterPin(storedPin);
  }

  bool _isWeakPin(String pin) {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) return true;
    // Todas iguales
    if (pin.split('').every((d) => d == pin[0])) return true;
    // Ascendente consecutivo
    final asc = pin.codeUnits;
    final isAsc = asc[1] == asc[0] + 1 &&
        asc[2] == asc[1] + 1 &&
        asc[3] == asc[2] + 1;
    // Descendente consecutivo
    final isDesc = asc[1] == asc[0] - 1 &&
        asc[2] == asc[1] - 1 &&
        asc[3] == asc[2] - 1;
    if (isAsc || isDesc) return true;
    // Patrones comunes
    const blacklist = {'0000', '1234', '4321', '1111', '2222', '3333'};
    return blacklist.contains(pin);
  }

  Future<bool> _promptCreatePin() async {
    String? error;
    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final pinCtrl = TextEditingController();
        final confirmCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Crear PIN de 4 dígitos'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pinCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: const InputDecoration(labelText: 'PIN'),
                  ),
                  TextField(
                    controller: confirmCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration:
                        const InputDecoration(labelText: 'Confirmar PIN'),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    final pin = pinCtrl.text.trim();
                    final confirm = confirmCtrl.text.trim();
                    if (pin != confirm) {
                      setState(() => error = 'Los PIN no coinciden');
                      return;
                    }
                    if (_isWeakPin(pin)) {
                      setState(() => error =
                          'PIN inválido. No uses secuencias ni repeticiones.');
                      return;
                    }
                    Navigator.of(context).pop(pin);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await PinService.setPin(result);
      return true;
    }
    return false;
  }

  Future<bool> _promptEnterPin(String storedPin) async {
    String? error;
    final result = await showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final pinCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Ingresa tu PIN'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pinCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: InputDecoration(
                      labelText: 'PIN',
                      errorText: error,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    final pin = pinCtrl.text.trim();
                    if (pin == storedPin) {
                      Navigator.of(context).pop(true);
                    } else {
                      setState(() => error = 'PIN incorrecto');
                    }
                  },
                  child: const Text('Aceptar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Olvidé el PIN'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) {
      // Olvidé el PIN
      return _handleForgotPin();
    }

    return result;
  }

  Future<bool> _handleForgotPin() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) {
      _showMessage('Inicia sesión de nuevo para recuperar el PIN.');
      return false;
    }
    final password = await _promptPassword(email);
    if (password == null) return false;
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final cred = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);
      await PinService.clearPin();
      _showMessage('PIN restablecido. Define uno nuevo.');
      return _promptCreatePin();
    } catch (e) {
      _showMessage('No se pudo validar la contraseña.');
      return false;
    }
  }

  Future<String?> _promptPassword(String email) async {
    final controller = TextEditingController();
    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Recuperar PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Correo: $email'),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Contraseña de la cuenta'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}