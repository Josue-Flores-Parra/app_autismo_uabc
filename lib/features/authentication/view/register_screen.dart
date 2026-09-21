import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../../../core/app_theme.dart';
import '../../settings/viewmodel/settings_viewmodel.dart';
import '../../telemetry/view/telemetry_consent_dialog.dart';
import '../../legal/data/legal_documents.dart';
import '../../legal/view/legal_document_screen.dart';
import '../../legal/view/legal_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _acceptedTerms = false;
  bool _showTermsError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _openConsentFlow() async {
    if (_acceptedTerms) {
      setState(() => _acceptedTerms = false);
      return;
    }
    final accepted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const _RegisterLegalConsentScreen()),
    );
    if (accepted == true && mounted) {
      setState(() {
        _acceptedTerms = true;
        _showTermsError = false;
      });
    }
  }

  Future<void> _handleRegister() async {
    setState(() => _showTermsError = !_acceptedTerms);
    if (!_formKey.currentState!.validate() || !_acceptedTerms) return;

    FocusScope.of(context).unfocus();

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final success = await authViewModel.register(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
      kLegalVersion,
    );

    if (success && mounted) {
      // Consentimiento de telemetría: se informa una sola vez por cuenta,
      // inmediatamente después de crearla. El consentimiento se guarda con el
      // UID de la cuenta recién creada (no del dispositivo).
      final settings = Provider.of<SettingsViewModel>(context, listen: false);
      if (!settings.telemetryOnboardingShown) {
        final accepted = await showTelemetryConsentDialog(context);
        await settings.completeTelemetryOnboarding(
          accepted: accepted,
          uid: authViewModel.lastRegisteredUid,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    const avatarScale = 0.65;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(gradient: colors.backgroundGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              '¡Crea tu cuenta!',
                              style: TextStyle(
                                fontFamily: AppFonts.display,
                                fontSize: 28,
                                color: colors.ink,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            Center(
                              child: Image.asset(
                                'assets/images/icon-questionmark2x.png',
                                width: 296 * avatarScale,
                                height: 468 * avatarScale,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                            const SizedBox(height: 32),

                            Consumer<AuthViewModel>(
                              builder: (context, authViewModel, child) {
                                if (authViewModel.errorMessage != null) {
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: scheme.errorContainer,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.input,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: scheme.onErrorContainer,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            authViewModel.errorMessage!,
                                            style: TextStyle(
                                              color: scheme.onErrorContainer,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),

                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu nombre';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu correo electrónico';
                                }
                                if (!value.contains('@')) {
                                  return 'Ingresa un correo electrónico válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu contraseña';
                                }
                                if (value.length < 6) {
                                  return 'La contraseña debe tener al menos 6 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            InkWell(
                              borderRadius: BorderRadius.circular(
                                AppRadius.input,
                              ),
                              onTap: _openConsentFlow,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Checkbox(
                                      value: _acceptedTerms,
                                      onChanged: (_) => _openConsentFlow(),
                                    ),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            color: colors.ink,
                                            fontSize: 13,
                                          ),
                                          children: [
                                            const TextSpan(
                                              text: 'He leído y acepto los ',
                                            ),
                                            TextSpan(
                                              text: 'Términos y Condiciones',
                                              style: TextStyle(
                                                color: colors.accent,
                                                fontWeight: FontWeight.bold,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                              recognizer: TapGestureRecognizer()
                                                ..onTap = _openConsentFlow,
                                            ),
                                            const TextSpan(text: ' y el '),
                                            TextSpan(
                                              text: 'Aviso de Privacidad',
                                              style: TextStyle(
                                                color: colors.accent,
                                                fontWeight: FontWeight.bold,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                              recognizer: TapGestureRecognizer()
                                                ..onTap = _openConsentFlow,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_showTermsError)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 12,
                                  top: 4,
                                ),
                                child: Text(
                                  'Debes aceptar los términos para continuar',
                                  style: TextStyle(
                                    color: scheme.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 20),

                            Consumer<AuthViewModel>(
                              builder: (context, authViewModel, child) {
                                return FilledButton(
                                  onPressed: authViewModel.isLoading
                                      ? null
                                      : _handleRegister,
                                  child: authViewModel.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Registrarse'),
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '¿Ya tienes una cuenta?',
                                  style: TextStyle(color: colors.inkSoft),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Provider.of<AuthViewModel>(
                                      context,
                                      listen: false,
                                    ).clearError();
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Inicia sesión'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RegisterLegalConsentScreen extends StatefulWidget {
  const _RegisterLegalConsentScreen();

  @override
  State<_RegisterLegalConsentScreen> createState() =>
      _RegisterLegalConsentScreenState();
}

class _RegisterLegalConsentScreenState
    extends State<_RegisterLegalConsentScreen> {
  bool _termsRead = false;
  bool _privacyRead = false;
  bool _accepted = false;

  bool get _bothRead => _termsRead && _privacyRead;
  bool get _canAccept => _bothRead && _accepted;

  Future<void> _openDocument(LegalDocument document, bool isTerms) async {
    final leido = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            LegalDocumentScreen(document: document, trackReading: true),
      ),
    );
    if (leido != true || !mounted) return;
    setState(() {
      if (isTerms) {
        _termsRead = true;
      } else {
        _privacyRead = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final terms = termsOfUse('es');
    final privacy = privacyNotice('es');

    return Scaffold(
      backgroundColor: LegalPalette.paper,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                children: [
                  const Text(
                    'Lee y acepta los documentos',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: LegalPalette.ink,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Antes de crear tu cuenta debes leer y aceptar los documentos '
                    'que rigen el uso de Appy y el tratamiento de datos personales.',
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.5,
                      color: LegalPalette.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: LegalPalette.rule,
                  ),
                  _docRow(
                    terms.shortTitle,
                    _termsRead,
                    () => _openDocument(terms, true),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: LegalPalette.rule,
                  ),
                  _docRow(
                    privacy.shortTitle,
                    _privacyRead,
                    () => _openDocument(privacy, false),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: LegalPalette.rule,
                  ),
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: _bothRead
                        ? () => setState(() => _accepted = !_accepted)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _accepted,
                            onChanged: _bothRead
                                ? (v) => setState(() => _accepted = v ?? false)
                                : null,
                            activeColor: LegalPalette.brand,
                            side: const BorderSide(
                              color: LegalPalette.inkSoft,
                              width: 1.6,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'He leído y acepto los Términos y Condiciones y el '
                              'Aviso de Privacidad, y manifiesto que soy mayor de '
                              'edad y que soy madre, padre o tutor legal de quien '
                              'usará la aplicación.',
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.55,
                                color: _bothRead
                                    ? LegalPalette.ink
                                    : LegalPalette.inkSoft,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!_bothRead)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Abre y lee ambos documentos para poder aceptar.',
                        style: TextStyle(
                          fontSize: 13,
                          color: LegalPalette.inkSoft,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
              decoration: const BoxDecoration(
                color: LegalPalette.paper,
                border: Border(top: BorderSide(color: LegalPalette.rule)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: LegalPalette.inkSoft,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _canAccept
                          ? () => Navigator.of(context).pop(true)
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: LegalPalette.brand,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: LegalPalette.rule,
                        disabledForegroundColor: LegalPalette.inkSoft,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Confirmar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _docRow(String title, bool read, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: LegalPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    read ? 'Leído ✓' : 'Sin leer. Toca para abrir',
                    style: TextStyle(
                      fontSize: 13,
                      color: read ? LegalPalette.brand : LegalPalette.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              read ? Icons.check_circle : Icons.chevron_right,
              color: read ? LegalPalette.brand : LegalPalette.inkSoft,
            ),
          ],
        ),
      ),
    );
  }
}
