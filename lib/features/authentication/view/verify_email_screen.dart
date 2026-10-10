import 'dart:async';

import 'package:appy/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../viewmodel/auth_viewmodel.dart';

/// Pide a la persona adulta que confirme su correo antes de usar la app.
///
/// Es el primer paso del consentimiento parental: ningún perfil infantil se
/// crea ni se usa hasta que el correo de la cuenta está verificado. `AuthGate`
/// la muestra mientras `User.emailVerified` sea falso y avanza solo cuando
/// [AuthViewModel.checkEmailVerified] confirma la verificación.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, this.resendCooldown = 60});

  /// Segundos de espera entre reenvíos, para no saturar el límite de Firebase.
  final int resendCooldown;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with WidgetsBindingObserver {
  Timer? _cooldownTimer;
  int _secondsLeft = 0;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // El registro ya envió el primer correo; se espera antes de permitir otro.
    _startCooldown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver de la app de correo se revisa sin que la persona tenga que
    // tocar el botón; si aún no confirma, no se muestra ningún aviso.
    if (state == AppLifecycleState.resumed) _check(silent: true);
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _secondsLeft = widget.resendCooldown);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final sent = await context.read<AuthViewModel>().sendEmailVerification();
    if (!mounted) return;
    if (sent) _startCooldown();
    messenger.showSnackBar(
      SnackBar(
        content: Text(sent ? l10n.verifyEmailSent : l10n.verifyEmailSendFailed),
      ),
    );
  }

  Future<void> _check({bool silent = false}) async {
    if (_checking) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _checking = true);
    final verified = await context.read<AuthViewModel>().checkEmailVerified();
    if (!mounted) return;
    setState(() => _checking = false);
    if (!verified && !silent) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.verifyEmailNotYet)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    final email = context.watch<AuthViewModel>().currentUser?.email ?? '';

    return Container(
      decoration: BoxDecoration(gradient: colors.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.mark_email_unread_outlined,
                      size: 72,
                      color: colors.ink,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.verifyEmailTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 28,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.input),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.verifyEmailBody(email),
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.45,
                              color: colors.ink,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.verifyEmailSpamHint,
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _checking ? null : _check,
                      child: _checking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.verifyEmailConfirmed),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _secondsLeft > 0 ? null : _resend,
                      child: Text(
                        _secondsLeft > 0
                            ? l10n.verifyEmailResendIn(_secondsLeft)
                            : l10n.verifyEmailResend,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.read<AuthViewModel>().logout(),
                      child: Text(l10n.logout),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
