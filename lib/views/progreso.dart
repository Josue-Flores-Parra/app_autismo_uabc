import 'package:flutter/material.dart';
import '../resources/colors_app.dart';
import '../resources/strings_utils.dart';

class ProgresoModulosScreen extends StatelessWidget {
  final List<Map<String, dynamic>> modulos = [
    {
      'titulo': AppStrings.alimentacion,
      'icono': Icons.restaurant,
      'color': AppColors.alimentacion,
      'progreso': 0.7
    },
    {
      'titulo': AppStrings.higiene,
      'icono': Icons.clean_hands,
      'color': AppColors.higiene,
      'progreso': 0.4
    },
    {
      'titulo': AppStrings.interaccionSocial,
      'icono': Icons.people,
      'color': AppColors.interaccionSocial,
      'progreso': 0.9
    },
    {
      'titulo': AppStrings.cuidadoPersonal,
      'icono': Icons.face,
      'color': AppColors.cuidadoPersonal,
      'progreso': 0.9
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        title: Text(
          AppStrings.tituloAppBar,
          style: TextStyle(color: AppColors.appBarText),
        ),
        centerTitle: true,
        backgroundColor: AppColors.appBarBackground,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: modulos.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 60,
            crossAxisSpacing: 24,
            childAspectRatio: 0.7,
          ),
          itemBuilder: (context, index) {
            final modulo = modulos[index];
            return Card(
              elevation: 4,
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: modulo['color'],
                      child: Icon(
                        modulo['icono'],
                        size: 36,
                        color: AppColors.base,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      modulo['titulo'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: modulo['progreso'],
                        color: modulo['color'],
                        backgroundColor: AppColors.progressBackground.shade300,
                        minHeight: 12,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${(modulo['progreso'] * 100).toInt()}%',
                      style: TextStyle(
                        color: modulo['color'],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
