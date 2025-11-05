import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/modulo_info.dart';
import '../viewmodel/module_list_viewmodel.dart';
import 'level_timeline_screen.dart';

/// Pantalla principal que muestra la lista de módulos de aprendizaje.
/// Esta es la VISTA en el patrón MVVM - solo se encarga de mostrar los datos.
class ModuleListScreen extends StatelessWidget {
  const ModuleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Mis Módulos',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xF20D3B52), Color(0xFF091F2C)],
          ),
        ),
        child: Consumer<ModuleListViewModel>(
          builder: (context, viewModel, child) {
            return ModulosGridView(
              modulos: viewModel.modulos,
              nombreUsuario: viewModel.nombreUsuario,
              nivelUsuario: viewModel.nivelUsuario,
            );
          },
        ),
      ),
    );
  }
}

/// Widget que muestra el grid de módulos.
/// Separado para mantener el código organizado.
class ModulosGridView extends StatelessWidget {
  final List<ModuloInfo> modulos;
  final String nombreUsuario;
  final int nivelUsuario;

  const ModulosGridView({
    super.key,
    required this.modulos,
    required this.nombreUsuario,
    required this.nivelUsuario,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          /// Header con información del usuario
          _buildUserHeader(),

          /// Grid de módulos
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 5 / 8,
                crossAxisSpacing: 7,
                mainAxisSpacing: 7,
              ),
              itemCount: modulos.length,
              itemBuilder: (context, index) {
                return ModuloPlantilla(modulo: modulos[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el header con información del usuario
  Widget _buildUserHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C5F7A), Color(0xFF1A3D52)],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0x66FFFFFF), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0x4DFFFFFF), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.asset(
                'assets/images/CARITAROBOT.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡HOLA!',
                  style: TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nombreUsuario,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFE55C), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xCCFFD700),
                  blurRadius: 15,
                  offset: Offset(0, 0),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Color(0x80000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFF000000),
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  'NIVEL $nivelUsuario',
                  style: const TextStyle(
                    color: Color(0xFF000000),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget que representa una tarjeta individual de módulo.
/// Muestra toda la información del módulo y cambia su apariencia según el estado.
class ModuloPlantilla extends StatelessWidget {
  final ModuloInfo modulo;

  const ModuloPlantilla({super.key, required this.modulo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!modulo.bloqueado) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LevelTimelineScreen(
                moduleId: modulo.id,
                backgroundImagePath: modulo.imagenPath,
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xE65B8DB3), Color(0xCC4A7499)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x997BA5C9), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0xCC2A4A5C),
              blurRadius: 25,
              offset: Offset(0, 12),
              spreadRadius: 3,
            ),
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 35,
              offset: Offset(0, 18),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
          child: Column(
            children: [
              /// Imagen del módulo con overlays
              Expanded(
                child: Stack(
                  children: [
                    _buildModuleImage(),
                    if (modulo.bloqueado) _buildLockedOverlay(),
                    _buildLevelBadge(),
                    _buildStarsIndicator(),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              /// Botón del título
              _buildTitleButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la imagen del módulo
  Widget _buildModuleImage() {
    return Center(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: modulo.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x997BA5C9), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x80000000),
              blurRadius: 30,
              spreadRadius: 5,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(modulo.imagenPath, fit: BoxFit.contain),
        ),
      ),
    );
  }

  /// Construye el overlay cuando está bloqueado
  Widget _buildLockedOverlay() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xE0000000),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xCC2A2A2A), Color.fromARGB(223, 46, 43, 43)],
        ),
      ),
      child: Center(
        child: Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFD700),
            border: Border.all(color: const Color(0xFFFFE55C), width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0xBBFFD700),
                blurRadius: 20,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Color(0x88FFD700),
                blurRadius: 35,
                spreadRadius: 10,
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_rounded,
            size: 55,
            color: Color.fromARGB(255, 105, 92, 13),
          ),
        ),
      ),
    );
  }

  /// Construye el badge del nivel
  Widget _buildLevelBadge() {
    return Positioned(
      top: 0,
      left: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFFFFFFF), width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0xFFFFFFFF), blurRadius: 8, spreadRadius: 2),
          ],
        ),
        child: Text(
          'NV ${modulo.nivel}',
          style: const TextStyle(
            color: Color(0xFF000000),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Construye el indicador de estrellas
  Widget _buildStarsIndicator() {
    return Positioned(
      top: 0,
      right: 0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          bool isRellena = index < modulo.estrellas;

          return Container(
            margin: const EdgeInsets.only(left: 2),
            decoration: BoxDecoration(
              boxShadow: isRellena
                  ? const [
                      BoxShadow(
                        color: Color(0xFFFFD700),
                        blurRadius: 15,
                        spreadRadius: 0.000003,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.star,
                  size: 18,
                  color: isRellena
                      ? const Color.fromARGB(150, 255, 158, 1)
                      : const Color(0xFF2A2A2A),
                ),
                Icon(
                  Icons.star,
                  size: 17,
                  color: isRellena
                      ? const Color(0xFFFFD700)
                      : const Color.fromARGB(255, 136, 133, 133),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Construye el botón del título
  Widget _buildTitleButton() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: modulo.bloqueado
                    ? const [Color(0xFF5A6B7A), Color(0xFF3E4B5A)]
                    : const [Color(0xFF92C5BC), Color(0xFF5A97B8)],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: modulo.bloqueado
                    ? const Color(0xFF6B7B8C)
                    : const Color(0xFFB0D9D1),
                width: 2,
              ),
              boxShadow: [
                const BoxShadow(
                  color: Color(0x4DFFFFFF),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                  spreadRadius: 0,
                ),
                if (!modulo.bloqueado)
                  const BoxShadow(
                    color: Color(0x665A97B8),
                    blurRadius: 15,
                    offset: Offset(0, 0),
                    spreadRadius: 1,
                  ),
                const BoxShadow(
                  color: Color(0x80000000),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                modulo.titulo,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
