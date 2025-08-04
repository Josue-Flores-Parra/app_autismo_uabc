import 'package:flutter/material.dart';
import '../resources/colors_app.dart';
import '../resources/strings_utils.dart';

class AlimentacionScreen extends StatefulWidget {
  const AlimentacionScreen({super.key});

  @override
  State<AlimentacionScreen> createState() => _AlimentacionScreenState();
}

class _AlimentacionScreenState extends State<AlimentacionScreen> {
  final List<Map<String, dynamic>> _levels = [
    {'id': 1, 'title': AppStrings.nivel1, 'completed': false},
    {'id': 2, 'title': AppStrings.nivel2, 'completed': false},
    {'id': 3, 'title': AppStrings.nivel3, 'completed': false},
  ];

  bool get _allLevelsCompleted => _levels.every((level) => level['completed'] == true);

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.moduloAlimentacion),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              '¡Bienvenido al módulo de Alimentación! Completa los niveles para avanzar.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 1.2,
                ),
                itemCount: _levels.length,
                itemBuilder: (context, index) {
                  final level = _levels[index];
                  return GestureDetector(
                    onTap: () async {
                      final bool? levelCompleted = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LevelScreen(
                            levelId: level['id'],
                            levelTitle: level['title'],
                          ),
                        ),
                      );

                      if (levelCompleted == true) {
                        setState(() {
                          level['completed'] = true;
                        });
                        _showMessage('¡Nivel ${level['id']} completado!');
                      } else if (levelCompleted == false) {
                        _showMessage('Nivel ${level['id']} no completado.');
                      }
                    },
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      color: level['completed'] ? Colors.green.shade100 : Colors.white,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            level['completed'] ? Icons.check_circle : Icons.circle_outlined,
                            color: level['completed'] ? Colors.green.shade700 : Colors.grey,
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            level['title'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: level['completed'] ? Colors.green.shade900 : Colors.black87,
                            ),
                          ),
                          if (level['completed'])
                            Padding(
                              padding: const EdgeInsets.only(top: 5.0),
                              child: Text(
                                '¡Listo!',
                                style: TextStyle(
                                  color: Colors.green.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                if (_allLevelsCompleted) {
                  Navigator.pop(context, true);
                } else {
                  _showMessage('Debes completar todos los niveles antes de finalizar el módulo.');
                }
              },
              icon: Icon(Icons.check_circle_outline),
              label: Text(AppStrings.botonFinal),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.green.shade700,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LevelScreen extends StatelessWidget {
  final int levelId;
  final String levelTitle;

  const LevelScreen({
    super.key,
    required this.levelId,
    required this.levelTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(levelTitle),
        backgroundColor: AppColors.base,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppStrings.tituloNivel,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blueAccent.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Este es el espacio donde se desarrollará la lección o actividad del nivel $levelId.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context, true);
              },
              icon: Icon(Icons.check),
              label: Text('Finalizar Nivel'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: AppColors.colorAlimentacion,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
            ),
            ],
        ),
      ),
    );
  }
}
