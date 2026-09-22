import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import '../../../shared/services/loading_service.dart';
import '../../../core/app_theme.dart';
import '../../onboarding/view/onboarding_screen.dart';

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
    // Reaccionar a registrationSuccess cuando vuelva el RegisterScreen via pop.
    // LoginScreen ya esta montado debajo de RegisterScreen, asi que initState
    // solo corre una vez al arranque — necesitamos un listener reactivo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      authViewModel.addListener(_onAuthChanged);
      // Cubrir el caso en que el flag ya este true al montar.
      _onAuthChanged();
    });
  }

  @override
  void dispose() {
    // Quitar el listener si llegamos a tener la referencia.
    if (_authViewModelRef != null) {
      _authViewModelRef!.removeListener(_onAuthChanged);
    }
    _emailController.removeListener(_clearErrorOnInput);
    _passwordController.removeListener(_clearErrorOnInput);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  AuthViewModel? _authViewModelRef;

  void _onAuthChanged() {
    if (!mounted) return;
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    _authViewModelRef ??= authViewModel;
    if (authViewModel.registrationSuccess) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showRegistrationCue(),
      );
    }
  }

  /// Muestra un cue en la parte superior-central tras un registro exitoso,
  /// luego limpia la bandera en AuthViewModel.
  void _showRegistrationCue() {
    if (!mounted) return;
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (!authViewModel.registrationSuccess) return;

    final colors = context.appColors;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 80,
        left: 24,
        right: 24,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: colors.success, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, color: colors.success),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Registro exitoso, puedes iniciar sesión ahora',
                      style: TextStyle(color: colors.ink, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
    authViewModel.clearRegistrationSuccess();
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

    // Capturar el servicio de carga ANTES de cualquier await: el context del
    // LoginScreen puede desmontarse cuando AuthGate swap a MainShell tras un
    // login exitoso. Operar sobre la referencia viva evita un Provider.of que
    // fallaria sobre un context ya disposed (loading colgado).
    final loadingService = Provider.of<LoadingService>(context, listen: false);

    // Mostrar pantalla de carga
    loadingService.showLoading('Iniciando sesión...');

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    // Ejecutar login y asegurar que la carga dure mínimo 2 segundos
    final loginFuture = authViewModel.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    final minDelayFuture = Future.delayed(const Duration(seconds: 2));

    // Esperar a que ambos se completen (login Y mínimo 2 segundos).
    // finally garantiza que el overlay se oculte aun si el await se resume
    // despues de que LoginScreen fue desmontado por el swap del AuthGate.
    try {
      await Future.wait([loginFuture, minDelayFuture]);
    } finally {
      loadingService.hideLoading();
    }

    // El swap a MainShell lo maneja AuthGate via Consumer<AuthViewModel>.
    // Los errores ya quedan registrados en AuthViewModel.errorMessage.
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

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
                              '¡Bienvenido! Por favor inicia sesión',
                              style: TextStyle(
                                fontSize: 16,
                                color: colors.inkSoft,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            // Imagen del personaje interactiva
                            Consumer<AuthViewModel>(
                              builder: (context, authViewModel, _) {
                                final imagePath =
                                    authViewModel.errorMessage != null
                                        ? 'assets/images/icon-questionmark2x.png'
                                        : 'assets/images/salute.png';

                                return Center(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (child, animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: ScaleTransition(
                                          scale: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      key: ValueKey(imagePath),
                                      borderRadius: BorderRadius.circular(32),
                                      child: Image.asset(
                                        imagePath,
                                        height: 180,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),

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
                                hintText: 'usuario@correo.com',
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
                            // Campo de texto para la contraseña
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Contraseña',
                                hintText: '••••••',
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
                            const SizedBox(height: 24),

                            // Botón para iniciar sesión con indicador de carga
                            Consumer<AuthViewModel>(
                              builder: (context, authViewModel, child) {
                                return FilledButton(
                                  onPressed: authViewModel.isLoading
                                      ? null
                                      : _handleLogin,
                                  child: authViewModel.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Iniciar sesión'),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            // Seccion para "¿Olvidaste tu contraseña?"
                            TextButton(
                              onPressed: () {
                                Provider.of<AuthViewModel>(
                                  context,
                                  listen: false,
                                ).clearError();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: const Text('¿Olvidaste tu contraseña?'),
                            ),
                            // Seccion para "¿No tienes una cuenta? Regístrate"
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '¿No tienes una cuenta?',
                                  style: TextStyle(color: colors.inkSoft),
                                ),
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
                                  child: const Text('Regístrate'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            // Boton ultra discreto para volver al Onboarding
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OnboardingScreen(
                                      onFinished: () => Navigator.pop(context),
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                'Ver introducción',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colors.inkSoft.withValues(alpha: 0.4),
                                  fontSize: 11,
                                ),
                              ),
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
