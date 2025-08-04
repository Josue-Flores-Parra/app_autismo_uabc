import 'package:flutter/material.dart';
import '../resources/colors_app.dart';
import '../resources/strings_utils.dart';
import '../utils/linea.dart';

import 'alimentacion.dart';
import 'higiene.dart';
import 'interaccion.dart';
import 'cuidado_personal.dart';

class Modulos extends StatefulWidget {
  @override
  _ScreenState createState() => _ScreenState();
}

class _ScreenState extends State<Modulos> {

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _stackKey = GlobalKey();
  final List<GlobalKey> _iconKeys = [];

  final List<Map<String, dynamic>> modulos = [
    {'titulo': AppStrings.moduloAlimentacion, 'icono': Icons.restaurant, 'color': AppColors.colorAlimentacion, 'bloqueado' : false, 'key': 'alimentacion'},
    {'titulo': AppStrings.moduloHigiene, 'icono': Icons.clean_hands, 'color': AppColors.colorHigiene, 'bloqueado' : true, 'key': 'higiene'},
    {'titulo': AppStrings.moduloInteraccion, 'icono': Icons.people, 'color': AppColors.colorInteraccion, 'bloqueado' : true, 'key': 'interaccion'},
    {'titulo': AppStrings.moduloCuidadoPersonal, 'icono': Icons.face, 'color': AppColors.colorCuidadoPersonal, 'bloqueado' : true, 'key': 'cuidado_personal'},
    {'titulo': AppStrings.bloqueado, 'icono': Icons.build, 'color': AppColors.colorBloqueado, 'bloqueado' : true},
  ];

  @override
  void initState() {
    super.initState();
    _iconKeys.addAll(List.generate(modulos.length, (_) => GlobalKey()));
    _scrollController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Offset> _getIconPositions() {
    final RenderBox? stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) return [];

    return _iconKeys.map((key) {
      final context = key.currentContext;
      if (context == null) return Offset.zero;
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      return renderBox.localToGlobal(Offset.zero, ancestor: stackBox) + Offset(40, 40);
    }).toList();
  }


  Widget _getModuleScreen(String moduleKey) {
    switch (moduleKey) {
      case 'alimentacion':
        return AlimentacionScreen();
      case 'higiene':
        return HigieneScreen();
      case 'interaccion':
        return InteraccionScreen();
      case 'cuidado_personal':
        return CuidadoPersonalScreen();
      default:
        return Modulos();
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.bienvenida),
        backgroundColor: AppColors.fondoAppBar,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            key: _stackKey,
            children: [
              // Line painter
              Positioned.fill(
                child: CustomPaint(
                  painter: Connector(_getIconPositions()),
                ),
              ),
              ListView.builder(
                controller: _scrollController,
                itemCount: modulos.length,
                padding: EdgeInsets.symmetric(vertical: 20),
                itemBuilder: (context, index) {
                  final modulo = modulos[index];
                  final bool isEven = index % 2 == 0;
                  final bool bloqueado = modulo['bloqueado'] == true || modulo['titulo'] == AppStrings.bloqueado;

                  return Row(
                    mainAxisAlignment: isEven ? MainAxisAlignment.start : MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: GestureDetector(
                          onTap: bloqueado
                              ? null
                              : () async {
                            final completado = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _getModuleScreen(modulo['key']),
                              ),
                            );
                            if (completado == true && index + 1 < modulos.length) {
                              setState(() {
                                modulos[index + 1]['bloqueado'] = false;
                              });
                            }
                          },
                          child: Column(
                            key: _iconKeys[index],
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor:
                                bloqueado ? Colors.grey.shade300 : modulo['color'],
                                child: Icon(
                                  modulo['icono'],
                                  size: 40,
                                  color: bloqueado ? Colors.grey : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                modulo['titulo'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: bloqueado ? Colors.grey : Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              )
            ],
          );
        },
      ),
    );
  }
}


class ModuloScreen extends StatelessWidget {
  final String titulo;

  const ModuloScreen({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Contenido del módulo: $titulo',
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context, true);
              },
              icon: Icon(Icons.check),
              label: Text(AppStrings.botonFinal),
            )

          ],
        ),
      ),
    );
  }
}
