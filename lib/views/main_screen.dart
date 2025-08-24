import 'package:flutter/material.dart';
import '../widgets/my_bottom_navigation_bar.dart';
import '../views/modulos.dart';
import 'progreso.dart';
import 'configuracion.dart';
import 'package:hive/hive.dart';
import '../models/usuario.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    Modulos(),
    ProgresoModulosScreen(),
    // 👇 Configuración no se pone aquí directo
    const SizedBox(),
  ];

  Usuario? usuarioActual;

  @override
  void initState() {
    super.initState();
    _cargarUsuarioActual();
  }

  void _cargarUsuarioActual() {
    final box = Hive.box<Usuario>('usuarios');
    if (box.isNotEmpty) {
      // Por ahora tomo el primero como ejemplo, aquí puedes poner tu lógica real
      usuarioActual = box.getAt(0);
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      _validarAccesoConfiguracion();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _validarAccesoConfiguracion() {
    if (usuarioActual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay usuario activo")),
      );
      return;
    }

    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmar acceso"),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: "Ingresa tu contraseña",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                if (passwordController.text == usuarioActual!.contrasena) {
                  Navigator.pop(context); // cerrar diálogo
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConfiguracionScreen(),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Contraseña incorrecta")),
                  );
                }
              },
              child: const Text("Acceder"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _screens[0],
          _screens[1],
          _screens[2], // Aquí está vacío porque configuracion se abre aparte
        ],
      ),
      bottomNavigationBar: MyBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}