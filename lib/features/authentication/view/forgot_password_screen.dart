import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../../../core/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Maneja el envío del formulario de recuperación de contraseña.
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _showSuccess = false);

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    final success = await authViewModel.resetPassword(
      _emailController.text.trim(),
    );

    if (success && mounted) {
      setState(() => _showSuccess = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    // El degradado envuelve al Scaffold para que la AppBar transparente
    // quede sobre el mismo fondo que el cuerpo.
    return Container(
      decoration: BoxDecoration(gradient: colors.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: const Text('Recuperar contraseña')),
        body: SafeArea(
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
                              'Appy',
                              style: TextStyle(
                                fontFamily: AppFonts.display,
                                fontSize: 40,
                                color: colors.ink,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Recupera tu contraseña',
                              style: TextStyle(
                                fontSize: 16,
                                color: colors.inkSoft,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            // Imagen del personaje sobre el formulario
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: Image.asset(
                                  'assets/images/forgot-password.png',
                                  height: 180,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Mensaje de éxito tras enviar el correo
                            if (_showSuccess)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.input,
                                  ),
                                  border: Border.all(
                                    color: colors.success,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: colors.success,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Si el correo está registrado, recibirás un enlace para restablecer tu contraseña.',
                                        style: TextStyle(color: colors.ink),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Mostrar mensaje de error si existe
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

                            // Campo de texto para el correo electrónico
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
                            const SizedBox(height: 24),

                            // Botón con indicador de carga
                            Consumer<AuthViewModel>(
                              builder: (context, authViewModel, child) {
                                return FilledButton(
                                  onPressed: authViewModel.isLoading
                                      ? null
                                      : _handleSubmit,
                                  child: authViewModel.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Enviar correo de recuperación',
                                        ),
                                );
                              },
                            ),
                            if (_showSuccess) ...[
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Volver a iniciar sesión'),
                              ),
                            ],
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
