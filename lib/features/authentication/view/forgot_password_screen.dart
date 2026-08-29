import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/auth_viewmodel.dart';

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

    final authViewModel = Provider.of<AuthViewModel>(
      context,
      listen: false,
    );

    final success = await authViewModel.resetPassword(
      _emailController.text.trim(),
    );

    if (success && mounted) {
      setState(() => _showSuccess = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF5B8DB3);
    const Color buttonColor = Color(0xFF5A97B8);
    const Color backgroundColor = Colors.white;
    const avatarScale = 0.65;

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        backgroundColor: primaryColor,
      ),
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
                          const Text(
                            'Recupera tu contraseña',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5B8DB3),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          Center(
                            child: Image.asset(
                              'assets/images/forgot-password.png',
                              width: 400 * avatarScale,
                              height: 400 * avatarScale,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Mensaje de éxito tras enviar el correo
                          if (_showSuccess)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.shade300,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Si el correo está registrado, recibirás un enlace para restablecer tu contraseña.',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                      ),
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
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          authViewModel.errorMessage!,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
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
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              labelStyle: TextStyle(color: Colors.black),
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: Icon(
                                Icons.email,
                                color: Colors.black54,
                              ),
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
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: buttonColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    textStyle: const TextStyle(fontSize: 18),
                                  ),
                                  onPressed: authViewModel.isLoading
                                      ? null
                                      : _handleSubmit,
                                  child: authViewModel.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Text(
                                          'Enviar correo de recuperación',
                                        ),
                                ),
                              );
                            },
                          ),
                          if (_showSuccess) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  'Volver a iniciar sesión',
                                  style: TextStyle(
                                    color: Color(0xFF5A97B8),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
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
    );
  }
}
