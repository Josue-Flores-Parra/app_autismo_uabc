import 'package:flutter/material.dart';
import '../model/modulo_info.dart';
import '../model/levels_models.dart';
import '../../../data/services/firestore_services.dart';

/*
ViewModel que maneja la lógica de negocio y el estado de la lista de módulos.
Extiende ChangeNotifier para poder notificar a las vistas cuando el estado cambia.
*/
class ModuleListViewModel extends ChangeNotifier {
  List<ModuloInfo> _modulos = [];
  final String _nombreUsuario = 'MrBeast';
  final int _nivelUsuario = 2;
  bool _isLoading = false;
  String? _errorMessage;

  final FirestoreService _firestoreService = FirestoreService();

  List<ModuloInfo> get modulos => _modulos;
  String get nombreUsuario => _nombreUsuario;
  int get nivelUsuario => _nivelUsuario;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /*
  Constructor que inicializa el ViewModel cargando los módulos.
  */
  ModuleListViewModel() {
    _cargarModulos();
  }

  /*
  Carga todos los módulos desde Firestore.
  No hay fallback - si falla, se muestra el error al usuario.
  */
  Future<void> _cargarModulos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Cargar TODOS los módulos desde Firestore
      final modulesData = await _firestoreService.getAllModules();

      if (modulesData.isEmpty) {
        _errorMessage = 'No se encontraron módulos en Firestore';
      } else {
        // Convertir datos de Firestore a objetos ModuloInfo
        _modulos = modulesData
            .map((data) => ModuloInfo.fromFirestore(data, estrellas: 0))
            .toList();
      }
    } catch (e) {
      _errorMessage = 'Error al cargar módulos: $e';
      _modulos = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /*
  Recarga los módulos desde Firestore
  */
  Future<void> recargarModulos() async {
    await _cargarModulos();
  }

  /*
  Obtiene los niveles de un módulo específico desde Firestore
  */
  Future<List<ModuleLevelInfo>> obtenerNivelesModulo(String moduleId) async {
    try {
      final levelsData = await _firestoreService.getModuleLevels(moduleId);

      final niveles = levelsData
          .map((data) => ModuleLevelInfo.fromFirestore(data))
          .toList();

      return niveles;
    } catch (e, stackTrace) {
      return [];
    }
  }

  /*
  Actualiza el número de estrellas conseguidas en un módulo específico.
  Valida que el índice y el número de estrellas sean válidos antes de actualizar.
  */
  void actualizarEstrellas(int indiceModulo, int nuevasEstrellas) {
    if (indiceModulo >= 0 && indiceModulo < _modulos.length) {
      if (nuevasEstrellas >= 0 && nuevasEstrellas <= 3) {
        final moduloActual = _modulos[indiceModulo];
        _modulos[indiceModulo] = ModuloInfo(
          id: moduloActual.id,
          titulo: moduloActual.titulo,
          estrellas: nuevasEstrellas,
          nivel: moduloActual.nivel,
          imagenPath: moduloActual.imagenPath,
          color: moduloActual.color,
          bloqueado: moduloActual.bloqueado,
          descripcion: moduloActual.descripcion,
        );
        notifyListeners();
      }
    }
  }

  /*
  Cambia el estado de un módulo de bloqueado a desbloqueado.
  Reconstruye el objeto ModuloInfo con el nuevo estado.
  */
  void desbloquearModulo(int indiceModulo) {
    if (indiceModulo >= 0 && indiceModulo < _modulos.length) {
      final moduloActual = _modulos[indiceModulo];
      _modulos[indiceModulo] = ModuloInfo(
        id: moduloActual.id,
        titulo: moduloActual.titulo,
        estrellas: moduloActual.estrellas,
        nivel: moduloActual.nivel,
        imagenPath: moduloActual.imagenPath,
        color: moduloActual.color,
        bloqueado: false,
        descripcion: moduloActual.descripcion,
      );
      notifyListeners();
    }
  }
}
