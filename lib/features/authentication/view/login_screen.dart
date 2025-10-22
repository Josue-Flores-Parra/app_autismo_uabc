import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../../home/view/main_shell.dart';
import 'register_screen.dart';
import '../../../shared/widgets/loading_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para los campos de texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  // Estado local para errores de validación
  bool _hasValidationError = false;

  @override
  void initState() {
    super.initState();
    // Agregar listeners para limpiar errores cuando el usuario empiece a escribir
    _emailController.addListener(_clearErrorOnInput);
    _passwordController.addListener(_clearErrorOnInput);
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearErrorOnInput);
    _passwordController.removeListener(_clearErrorOnInput);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Limpia el error cuando el usuario empieza a escribir
  void _clearErrorOnInput() {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (authViewModel.errorMessage != null) {
      authViewModel.clearError();
    }
    // También limpiar errores de validación local
    if (_hasValidationError) {
      setState(() {
        _hasValidationError = false;
      });
    }
  }

  /// Maneja el proceso de inicio de sesión
  Future<void> _handleLogin() async {
    // Validar el formulario
    if (!_formKey.currentState!.validate()) {
      // Marcar que hay un error de validación
      setState(() {
        _hasValidationError = true;
      });
      return;
    }

    // Limpiar errores de validación si el formulario es válido
    setState(() {
      _hasValidationError = false;
    });

    // Ocultar el teclado
    FocusScope.of(context).unfocus();

    // Mostrar pantalla de carga
    LoadingHook.show(context, 'Iniciando sesión...');

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    // Ejecutar login y asegurar que la carga dure mínimo 2 segundos
    final loginFuture = authViewModel.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    
    final minDelayFuture = Future.delayed(const Duration(seconds: 2));
    
    // Esperar a que ambos se completen (login Y mínimo 2 segundos)
    final results = await Future.wait([loginFuture, minDelayFuture]);
    final success = results[0] as bool;

    // Ocultar pantalla de carga
    LoadingHook.hide(context);

    if (success && mounted) {
      // Navegar a MainShell si el login fue exitoso
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definir la paleta de colores
    const Color primaryColor = Color(0xFF5B8DB3);
    const Color buttonColor = Color(0xFF5A97B8);
    const Color backgroundColor = Colors.white;
    const avatarScale = 0.65; // escala para la imagen del avatar

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Appy'),
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
                          // Texto de bienvenida en la parte superior centrado
                          const Text(
                            '¡Bienvenido! Por favor inicia sesión',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5B8DB3),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          // Imagen de saludo del avatar (centrada) - cambia según el estado de error
                          Consumer<AuthViewModel>(
                            builder: (context, authViewModel, child) {
                              // Determinar qué imagen mostrar según si hay error o no
                              // Considerar tanto errores de AuthViewModel como errores de validación local
                              final bool hasAnyError = authViewModel.errorMessage != null || _hasValidationError;
                              final String imagePath = hasAnyError
                                  ? 'assets/images/icon-questionmark2x.png'
                                  : 'assets/images/salute.png';
                              
                              return Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 800),
                                  switchInCurve: Curves.easeInOutCubic,
                                  switchOutCurve: Curves.easeInOutCubic,
                                  transitionBuilder: (Widget child, Animation<double> animation) {
                                    return FadeTransition(
                                      opacity: Tween<double>(
                                        begin: 0.0,
                                        end: 1.0,
                                      ).animate(CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeInOutCubic,
                                      )),
                                      child: ScaleTransition(
                                        scale: Tween<double>(
                                          begin: 0.8,
                                          end: 1.0,
                                        ).animate(CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.elasticOut,
                                        )),
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0.0, 0.1),
                                            end: Offset.zero,
                                          ).animate(CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic,
                                          )),
                                          child: child,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Image.asset(
                                    imagePath,
                                    key: ValueKey(imagePath), // Importante para que AnimatedSwitcher detecte el cambio
                                    width: 400 * avatarScale,
                                    height: 486 * avatarScale,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 32),

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
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: Icon(Icons.email),
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
                          // Campo de texto para la contraseña
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: Icon(Icons.lock),
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
                          const SizedBox(height: 24),

                          // Botón para iniciar sesión con indicador de carga
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
                                      : _handleLogin,
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
                                      : const Text('Iniciar sesión'),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          // Seccion para "¿Olvidaste tu contraseña?"
                          TextButton(
                            onPressed: () {
                              // TODO: Implementar navegación a recuperación de contraseña
                            },
                            child: const Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(color: Color(0xFF5A97B8)),
                            ),
                          ),
                          // Seccion para "¿No tienes una cuenta? Regístrate"
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('¿No tienes una cuenta?'),
                              TextButton(
                                onPressed: () {
                                  // Limpiar errores antes de navegar
                                  Provider.of<AuthViewModel>(
                                    context,
                                    listen: false,
                                  ).clearError();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegisterScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Regístrate',
                                  style: TextStyle(color: Color(0xFF5A97B8)),
                                ),
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
    );
  }
}