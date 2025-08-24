import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/usuario.dart';
import 'main_screen.dart';
import 'registro.dart';
import 'login.dart';

class InicioRapidoScreen extends StatefulWidget {
  const InicioRapidoScreen({super.key});

  @override
  State<InicioRapidoScreen> createState() => _InicioRapidoScreenState();
}

class _InicioRapidoScreenState extends State<InicioRapidoScreen> {
  late Box<Usuario> _usuarioBox;
  List<Usuario> _usuarios = [];

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  void _cargarUsuarios() {
    _usuarioBox = Hive.box<Usuario>('usuarios');
    setState(() {
      _usuarios = _usuarioBox.values.toList();
    });

    // Si no hay usuarios guardados, ir a registro
    if (_usuarios.isEmpty) {
      Future.delayed(Duration.zero, () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RegistroScreen()),
        );
      });
    }
  }

  void _seleccionarUsuario(Usuario usuario) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Bienvenido ${usuario.nombre} 👋")),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: _usuarios.isEmpty
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Selecciona tu usuario",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ..._usuarios.map((usuario) {
                    return Card(
                      child: ListTile(
                        title: Text(usuario.nombre),
                        subtitle: Text(usuario.correo),
                        onTap: () => _seleccionarUsuario(usuario),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text("Iniciar sesión con otra cuenta"),
                  ),
                ],
              ),
      ),
    );
  }
}
