import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/usuario.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  late Box<Usuario> usuariosBox;

  @override
  void initState() {
    super.initState();
    usuariosBox = Hive.box<Usuario>('usuarios');
  }

  void _eliminarCuenta(int index) {
    final usuario = usuariosBox.getAt(index);
    usuariosBox.deleteAt(index);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Cuenta de ${usuario?.nombre} eliminada")),
    );
    setState(() {}); // Actualiza la lista
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configuración")),
      body: ListView.builder(
        itemCount: usuariosBox.length,
        itemBuilder: (context, index) {
          final usuario = usuariosBox.getAt(index);
          return ListTile(
            title: Text(usuario?.nombre ?? 'Usuario desconocido'),
            subtitle: Text(usuario?.correo ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _eliminarCuenta(index),
            ),
          );
        },
      ),
    );
  }
}