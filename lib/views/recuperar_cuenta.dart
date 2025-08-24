import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/usuario.dart';

class RecuperarCuentaScreen extends StatefulWidget {
  const RecuperarCuentaScreen({super.key});

  @override
  State<RecuperarCuentaScreen> createState() => _RecuperarCuentaScreenState();
}

class _RecuperarCuentaScreenState extends State<RecuperarCuentaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controladores
  final _correoController = TextEditingController();
  final _nuevaContrasenaController = TextEditingController();
  final _repetirContrasenaController = TextEditingController();
  final _edadController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _escuelaController = TextEditingController();
  final _gradoController = TextEditingController();

  bool _correoValidado = false;
  Usuario? _usuarioEncontrado;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Paso 1: Validar correo
  void _validarCorreo() {
    final box = Hive.box<Usuario>('usuarios');
    final usuario = box.values.firstWhere(
          (u) => u.correo == _correoController.text.trim(),
      orElse: () => Usuario(nombre: '', edad: 0, ciudad: '', escuela: '', grado: '', correo: '', contrasena: ''),
    );

    if (usuario.correo.isNotEmpty) {
      setState(() {
        _correoValidado = true;
        _usuarioEncontrado = usuario;
      });
    } else {
      _mostrarDialogo("No se encontró ninguna cuenta con ese correo.");
    }
  }

  // Paso 2: Cambiar contraseña
  void _cambiarContrasena() {
    if (_nuevaContrasenaController.text.isEmpty ||
        _repetirContrasenaController.text.isEmpty) {
      _mostrarDialogo("Por favor, completa ambos campos.");
      return;
    }

    if (_nuevaContrasenaController.text !=
        _repetirContrasenaController.text) {
      _mostrarDialogo("Las contraseñas no coinciden.");
      return;
    }

    final box = Hive.box<Usuario>('usuarios');
    final index = box.values.toList().indexOf(_usuarioEncontrado!);
    final usuarioActualizado = Usuario(
      nombre: _usuarioEncontrado!.nombre,
      edad: _usuarioEncontrado!.edad,
      ciudad: _usuarioEncontrado!.ciudad,
      escuela: _usuarioEncontrado!.escuela,
      grado: _usuarioEncontrado!.grado,
      correo: _usuarioEncontrado!.correo,
      contrasena: _nuevaContrasenaController.text,
    );

    box.putAt(index, usuarioActualizado);

    _mostrarDialogo("Contraseña actualizada con éxito.");
    setState(() {
      _correoValidado = false;
      _correoController.clear();
      _nuevaContrasenaController.clear();
      _repetirContrasenaController.clear();
    });
  }

  void _recuperarCorreo() {
    final box = Hive.box<Usuario>('usuarios');
    final usuario = box.values.firstWhere(
          (u) =>
      u.edad.toString() == _edadController.text &&
          u.ciudad.toLowerCase() == _ciudadController.text.toLowerCase() &&
          u.escuela.toLowerCase() == _escuelaController.text.toLowerCase() &&
          u.grado.toLowerCase() == _gradoController.text.toLowerCase(),
      orElse: () => Usuario(nombre: '', edad: 0, ciudad: '', escuela: '', grado: '', correo: '', contrasena: ''),
    );

    if (usuario.correo.isNotEmpty) {
      _mostrarDialogo("Tu correo es: ${usuario.correo}");
    } else {
      _mostrarDialogo("No se encontró ninguna cuenta con esos datos.");
    }
  }

  void _mostrarDialogo(String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Resultado"),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recuperar Cuenta"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Olvidé mi contraseña"),
            Tab(text: "Olvidé mi correo"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1 - Recuperar contraseña
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (!_correoValidado) ...[
                  TextField(
                    controller: _correoController,
                    decoration: const InputDecoration(labelText: "Correo"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _validarCorreo,
                    child: const Text("Validar correo"),
                  ),
                ] else ...[
                  TextField(
                    controller: _nuevaContrasenaController,
                    decoration:
                    const InputDecoration(labelText: "Nueva contraseña"),
                    obscureText: true,
                  ),
                  TextField(
                    controller: _repetirContrasenaController,
                    decoration:
                    const InputDecoration(labelText: "Repetir nueva contraseña"),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _cambiarContrasena,
                    child: const Text("Guardar nueva contraseña"),
                  ),
                ]
              ],
            ),
          ),

          // TAB 2 - Recuperar correo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _edadController,
                  decoration: const InputDecoration(labelText: "Edad"),
                ),
                TextField(
                  controller: _ciudadController,
                  decoration: const InputDecoration(labelText: "Ciudad"),
                ),
                TextField(
                  controller: _escuelaController,
                  decoration: const InputDecoration(labelText: "Escuela"),
                ),
                TextField(
                  controller: _gradoController,
                  decoration: const InputDecoration(labelText: "Grado"),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _recuperarCorreo,
                  child: const Text("Recuperar Correo"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
