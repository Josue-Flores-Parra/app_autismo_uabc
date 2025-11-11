import 'package:flutter/material.dart';
import '../features/learning_module/viewmodel/module_list_viewmodel.dart';
import '../features/learning_module/model/levels_models.dart';

/*
Widget de prueba para verificar que los datos se cargan correctamente desde Firestore.
Se puede agregar este widget a la app temporalmente para probar la conexión con Firestore.
*/
class FirestoreDebugScreen extends StatefulWidget {
  const FirestoreDebugScreen({super.key});

  @override
  State<FirestoreDebugScreen> createState() => _FirestoreDebugScreenState();
}

class _FirestoreDebugScreenState extends State<FirestoreDebugScreen> {
  late ModuleListViewModel _viewModel;
  List<ModuleLevelInfo> _niveles = [];
  bool _loadingLevels = false;
  String _debugLog = '';

  @override
  void initState() {
    super.initState();
    _viewModel = ModuleListViewModel();
    _addLog('ViewModel inicializado');
    _testFirestoreConnection();
  }

  void _addLog(String message) {
    setState(() {
      _debugLog +=
          '\n[${DateTime.now().toString().substring(11, 19)}] $message';
    });
    print(message);
  }

  Future<void> _testFirestoreConnection() async {
    _addLog('Esperando que carguen los módulos...');

    // Esperar un poco para que cargue
    await Future.delayed(const Duration(seconds: 3));

    _addLog('Módulos cargados: ${_viewModel.modulos.length}');

    if (_viewModel.modulos.isNotEmpty) {
      final modulo = _viewModel.modulos.first;
      _addLog('Primer módulo: ${modulo.titulo} (ID: ${modulo.id})');
      _addLog('  - Color: ${modulo.color}');
      _addLog('  - Descripción: ${modulo.descripcion ?? "Sin descripción"}');

      // Intentar cargar niveles
      await _loadLevels('alimentacion_01');
    } else {
      _addLog('⚠️ No se cargaron módulos desde Firestore');
      _addLog('Error: ${_viewModel.errorMessage ?? "Sin error"}');
    }
  }

  Future<void> _loadLevels(String moduleId) async {
    setState(() {
      _loadingLevels = true;
    });

    _addLog('\n--- Cargando niveles de $moduleId ---');

    try {
      final niveles = await _viewModel.obtenerNivelesModulo(moduleId);

      setState(() {
        _niveles = niveles;
        _loadingLevels = false;
      });

      _addLog('✓ Niveles cargados: ${niveles.length}');

      if (niveles.isEmpty) {
        _addLog('⚠️ La lista de niveles está vacía');
        _addLog('Verifica que la subcolección "levels" existe en Firestore');
        _addLog('Ruta: modules/alimentacion_01/levels/');
      } else {
        for (var nivel in niveles) {
          _addLog('  ${nivel.orden}. ${nivel.titulo} (${nivel.id})');
        }
      }
    } catch (e) {
      _addLog('❌ Error al cargar niveles: $e');
      setState(() {
        _loadingLevels = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Firestore'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // Estado de carga
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado del ViewModel',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ListenableBuilder(
                  listenable: _viewModel,
                  builder: (context, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _viewModel.isLoading
                                  ? Icons.hourglass_empty
                                  : Icons.check_circle,
                              color: _viewModel.isLoading
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _viewModel.isLoading
                                  ? 'Cargando...'
                                  : 'Carga completa',
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Módulos: ${_viewModel.modulos.length}'),
                        if (_viewModel.errorMessage != null)
                          Text(
                            'Error: ${_viewModel.errorMessage}',
                            style: const TextStyle(color: Colors.red),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Módulos
          Expanded(
            child: ListView(
              children: [
                // Lista de módulos
                ListenableBuilder(
                  listenable: _viewModel,
                  builder: (context, child) {
                    return ExpansionTile(
                      title: Text('Módulos (${_viewModel.modulos.length})'),
                      leading: const Icon(Icons.folder),
                      initiallyExpanded: true,
                      children: _viewModel.modulos.map((modulo) {
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: modulo.color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          title: Text(modulo.titulo),
                          subtitle: Text(
                            modulo.descripcion ??
                                'Sin descripción\nID: ${modulo.id}',
                          ),
                          trailing: Text('⭐ ${modulo.estrellas}/3'),
                          onTap: () => _loadLevels(modulo.id),
                        );
                      }).toList(),
                    );
                  },
                ),

                // Lista de niveles
                ExpansionTile(
                  title: Text('Niveles (${_niveles.length})'),
                  leading: const Icon(Icons.layers),
                  initiallyExpanded: true,
                  children: _loadingLevels
                      ? [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ]
                      : _niveles.isEmpty
                      ? [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No hay niveles cargados.\nToca un módulo arriba para cargar sus niveles.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ]
                      : _niveles.map((nivel) {
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text('${nivel.orden}'),
                            ),
                            title: Text(nivel.titulo),
                            subtitle: Text(
                              'ID: ${nivel.id}\nTipo: ${nivel.actividadType}',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('⭐ ${nivel.estrellas}'),
                                Icon(
                                  nivel.estado == StateOfStep.completed
                                      ? Icons.check_circle
                                      : nivel.estado == StateOfStep.inProgress
                                      ? Icons.play_circle
                                      : Icons.lock,
                                  size: 16,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                ),

                // Log de debug
                ExpansionTile(
                  title: const Text('Log de Debug'),
                  leading: const Icon(Icons.bug_report),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey.shade900,
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _debugLog.isEmpty ? 'Sin logs aún...' : _debugLog,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'reload',
            onPressed: () async {
              _addLog('\n=== RECARGANDO MÓDULOS ===');
              await _viewModel.recargarModulos();
              _addLog('Recarga completa');
              await _testFirestoreConnection();
            },
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'clear',
            onPressed: () {
              setState(() {
                _debugLog = '';
                _niveles = [];
              });
              _addLog('Log limpiado');
            },
            child: const Icon(Icons.clear),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}
