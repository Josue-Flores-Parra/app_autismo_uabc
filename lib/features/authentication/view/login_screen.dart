import 'package:flutter/material.dart';
import 'register_screen.dart'; // Importar RegisterScreen

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Definir la paleta de colores
    const Color primaryColor = Color(0xFF5B8DB3);
    const Color buttonColor = Color(0xFF5A97B8);
    const Color backgroundColor = Colors.white;
    const avatarScale = 0.65; // escala para la imagen del avatar

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset:
          true, // Asegura que la UI se ajuste cuando aparece el teclado
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
        backgroundColor: primaryColor,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onTap: () => FocusScope.of(
                context,
              ).unfocus(), // Oculta el teclado al tocar fuera
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
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
                        // Imagen de saludo del avatar (centrada)
                        Center(
                          child: Image.asset(
                            'assets/images/icon-salute-hidden2x.png',
                            width: 200 * avatarScale,
                            height: 486 * avatarScale,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Campo de texto para el correo electrónico
                        TextField(
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Campo de texto para la contraseña
                        TextField(
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Botón para iniciar sesión
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontSize: 18),
                            ),
                            onPressed: () {
                              // TODO: añadir lógica de autenticación
                            },
                            child: const Text('Iniciar sesión'),
                          ),
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
                                // navegar a register_screen
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
            );
          },
        ),
      ),
    );
  }
}
