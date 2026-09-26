import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import 'pin_service.dart';

/// Gating de PIN para cambiar del perfil infantil a la zona parent.
///
/// La zona parent incluye ajustes de cuenta y administración de perfiles. El
/// mismo guard se usa desde el selector y el acceso en `ModuleListScreen`.
class SettingsAccessGuard {
  /// Devuelve `true` solo si el usuario definio o ingreso su PIN.
  static Future<bool> changePinFlow(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final current = await PinService.getPin(uid);
    if (current == null || !context.mounted) return false;

    final verified = await showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (c) => _PinDialog(storedPin: current),
    );
    if (verified != true || !context.mounted) return false;

    final newPin = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (c) => const _PinDialog(),
    );

    if (newPin != null) {
      await PinService.setPin(uid, newPin);
      return true;
    }
    return false;
  }

  static Future<bool> ensureAccess(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showMessage(context, 'Inicia sesión de nuevo para abrir Ajustes.');
      return false;
    }

    final storedPin = await PinService.getPin(uid);
    if (!context.mounted) return false;

    if (storedPin == null) {
      // On the first device setup there is no secret to verify yet. Requiring
      // the account password prevents a learner from claiming the parent area
      // by creating a PIN themselves.
      final passwordVerified = await _verifyParentPassword(context);
      if (!passwordVerified || !context.mounted) return false;
      return _promptCreatePin(context, uid);
    }
    return _promptEnterPin(context, uid, storedPin);
  }

  static Future<bool> _verifyParentPassword(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) return false;
    final password = await _promptPassword(context, email);
    if (password == null || password.isEmpty || !context.mounted) return false;
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
      return true;
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, 'No se pudo validar la contraseña.');
      }
      return false;
    }
  }

  static bool isWeakPin(String pin) {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) return true;
    // Todas iguales
    if (pin.split('').every((d) => d == pin[0])) return true;
    // Ascendente consecutivo
    final asc = pin.codeUnits;
    final isAsc =
        asc[1] == asc[0] + 1 && asc[2] == asc[1] + 1 && asc[3] == asc[2] + 1;
    // Descendente consecutivo
    final isDesc =
        asc[1] == asc[0] - 1 && asc[2] == asc[1] - 1 && asc[3] == asc[2] - 1;
    if (isAsc || isDesc) return true;
    // Patrones comunes
    const blacklist = {'0000', '1234', '4321', '1111', '2222', '3333'};
    return blacklist.contains(pin);
  }

  /// Pushes a PIN dialog and resolves only after its exit animation finishes.
  ///
  /// `showDialog` completes as soon as the dialog is popped, while its overlay
  /// is still animating out. Callers switch the profile gate right after a
  /// successful PIN, which used to swap the whole screen tree underneath that
  /// overlay and abort the navigation (the user had to tap a second time).
  /// Waiting for [Route.completed] avoids it, same as the profile dialogs.
  static Future<T?> _showPinDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
  }) async {
    final route = DialogRoute<T>(
      context: context,
      barrierDismissible: false,
      builder: builder,
    );
    final result = await Navigator.of(context, rootNavigator: true).push(route);
    await route.completed;
    return result;
  }

  static Future<bool> _promptCreatePin(BuildContext context, String uid) async {
    final result = await _showPinDialog<String?>(
      context: context,
      builder: (_) => const _PinDialog(),
    );

    if (result != null) {
      await PinService.setPin(uid, result);
      return true;
    }
    return false;
  }

  static Future<bool> _promptEnterPin(
    BuildContext context,
    String uid,
    String storedPin,
  ) async {
    final result = await _showPinDialog<bool?>(
      context: context,
      builder: (_) => _PinDialog(storedPin: storedPin),
    );

    if (!context.mounted) return false;
    if (result == null) {
      // Olvidé el PIN
      return _handleForgotPin(context, uid);
    }

    return result;
  }

  static Future<bool> _handleForgotPin(BuildContext context, String uid) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) {
      _showMessage(context, 'Inicia sesión de nuevo para recuperar el PIN.');
      return false;
    }
    final password = await _promptPassword(context, email);
    if (password == null || !context.mounted) return false;
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final cred = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);
      await PinService.clearPin(uid);
      if (!context.mounted) return false;
      _showMessage(context, 'PIN restablecido. Define uno nuevo.');
      return await _promptCreatePin(context, uid);
    } catch (e) {
      if (!context.mounted) return false;
      _showMessage(context, 'No se pudo validar la contraseña.');
      return false;
    }
  }

  static Future<String?> _promptPassword(
    BuildContext context,
    String email,
  ) async {
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
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña de la cuenta',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  static void _showMessage(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

/// Dialogo de PIN con casillas y teclado propio.
///
/// Con `storedPin` verifica y cierra con `true`/`false` (o `null` si el
/// usuario olvido el PIN). Sin `storedPin` crea uno en dos pasos y cierra con
/// el PIN elegido, o `null` al cancelar.
class _PinDialog extends StatefulWidget {
  const _PinDialog({this.storedPin});

  final String? storedPin;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  static const _length = 4;

  String _digits = '';
  String? _firstPin;
  String? _error;

  bool get _isCreate => widget.storedPin == null;

  String get _title {
    if (!_isCreate) return 'Ingresa tu PIN';
    return _firstPin == null ? 'Crear PIN de 4 dígitos' : 'Confirma tu PIN';
  }

  void _push(String digit) {
    if (_digits.length >= _length) return;
    setState(() {
      _digits += digit;
      _error = null;
    });
    if (_digits.length == _length) _submit();
  }

  void _pop() {
    if (_digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  void _fail(String message) {
    setState(() {
      _error = message;
      _digits = '';
    });
  }

  void _submit() {
    final pin = _digits;
    if (!_isCreate) {
      if (pin == widget.storedPin) {
        Navigator.of(context).pop(true);
      } else {
        _fail('PIN incorrecto');
      }
      return;
    }
    if (_firstPin == null) {
      if (SettingsAccessGuard.isWeakPin(pin)) {
        _fail('PIN inválido. No uses secuencias ni repeticiones.');
        return;
      }
      setState(() {
        _firstPin = pin;
        _digits = '';
      });
      return;
    }
    if (pin != _firstPin) {
      _firstPin = null;
      _fail('Los PIN no coinciden');
      return;
    }
    Navigator.of(context).pop(pin);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _pop();
      return KeyEventResult.handled;
    }
    final char = event.character;
    if (char != null && RegExp(r'^\d$').hasMatch(char)) {
      _push(char);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final errorColor = Theme.of(context).colorScheme.error;

    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: AlertDialog(
        scrollable: true,
        title: Text(_title, textAlign: TextAlign.center),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _length; i++)
                  Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 10),
                    child: _PinBox(filled: i < _digits.length),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Altura reservada para que el teclado no salte al aparecer el
            // mensaje de error.
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 36),
              child: _error == null
                  ? null
                  : Text(
                      _error!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: errorColor,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            for (final row in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['', '0', 'back'],
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final key in row)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _PinKey(
                          label: key,
                          onTap: switch (key) {
                            '' => null,
                            'back' => _pop,
                            _ => () => _push(key),
                          },
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          if (!_isCreate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Olvidé el PIN'),
            )
          else
            const SizedBox.shrink(),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_isCreate ? null : false),
            style: TextButton.styleFrom(foregroundColor: colors.inkSoft),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}

class _PinBox extends StatelessWidget {
  const _PinBox({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 52,
      height: 60,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(
          color: filled ? colors.accent : colors.surfaceBorder,
          width: filled ? 2 : 1.5,
        ),
      ),
      child: filled
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.ink,
                ),
              ),
            )
          : null,
    );
  }
}

class _PinKey extends StatelessWidget {
  const _PinKey({required this.label, required this.onTap});

  /// Digito, `'back'` para borrar o vacio para dejar el hueco.
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: 64,
      height: 64,
      child: onTap == null
          ? null
          : Material(
              color: colors.accentSoft,
              shape: CircleBorder(
                side: BorderSide(color: colors.surfaceBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Center(
                  child: label == 'back'
                      ? Icon(
                          Icons.backspace_outlined,
                          size: 22,
                          color: colors.ink,
                          semanticLabel: 'Borrar',
                        )
                      : Text(
                          label,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: colors.ink,
                          ),
                        ),
                ),
              ),
            ),
    );
  }
}
