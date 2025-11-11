import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/firestore_services.dart';
import '../model/modulo_info.dart';
import '../model/levels_models.dart';

/*
ViewModel unificado que maneja la lógica de negocio para módulos y niveles.
Conecta las pantallas ModuleListScreen y LevelTimelineScreen con Firestore.
Determina el estado de los niveles (completado, activo, bloqueado) basado en el progreso del usuario.
*/
class LearningViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Estado de módulos
  List<ModuloInfo> _modulos = [];
  bool _isLoadingModules = false;
  String? _errorMessageModules;

  // Estado de niveles
  Map<String, List<ModuleLevelInfo>> _moduleLevels = {};
  Map<String, Map<String, Map<String, dynamic>>> _userProgress = {};
  bool _isLoadingLevels = false;
  String? _errorMessageLevels;

  // Getters
  List<ModuloInfo> get modulos => _modulos;
  bool get isLoadingModules => _isLoadingModules;
  String? get errorMessageModules => _errorMessageModules;
  bool get isLoadingLevels => _isLoadingLevels;
  String? get errorMessageLevels => _errorMessageLevels;

  /*
  Obtiene el UID del usuario actual
  */
  String? get _currentUserId {
    return _auth.currentUser?.uid;
  }

  /*
  Constructor que inicializa el ViewModel cargando los módulos
  */
  LearningViewModel() {
    loadModules();
  }

  /*
  Carga todos los módulos desde Firestore
  */
  Future<void> loadModules() async {
    _isLoadingModules = true;
    _errorMessageModules = null;
    notifyListeners();

    try {
      final modulesData = await _firestoreService.getAllModules();

      if (modulesData.isEmpty) {
        _errorMessageModules = 'No se encontraron módulos en Firestore';
        _modulos = [];
      } else {
        // Convertir datos de Firestore a objetos ModuloInfo
        _modulos = modulesData
            .map((data) => ModuloInfo.fromFirestore(data, estrellas: 0))
            .toList();

        // Cargar progreso del usuario para calcular estrellas de cada módulo
        await _loadModulesProgress();
      }
    } catch (e) {
      _errorMessageModules = 'Error al cargar módulos: $e';
      _modulos = [];
    } finally {
      _isLoadingModules = false;
      notifyListeners();
    }
  }

  /*
  Carga el progreso del usuario para todos los módulos y calcula las estrellas
  */
  Future<void> _loadModulesProgress() async {
    if (_currentUserId == null) return;

    for (var modulo in _modulos) {
      try {
        final progress = await _firestoreService.getUserLevelsProgress(
          _currentUserId!,
          modulo.id,
        );

        // Calcular estrellas totales del módulo basado en el progreso
        int totalStars = 0;
        progress.forEach((levelId, levelProgress) {
          final stars = levelProgress['estrellas'] as int? ?? 0;
          totalStars += stars;
        });

        // Actualizar el módulo con las estrellas calculadas
        final index = _modulos.indexWhere((m) => m.id == modulo.id);
        if (index != -1) {
          _modulos[index] = ModuloInfo(
            id: modulo.id,
            titulo: modulo.titulo,
            estrellas: totalStars,
            nivel: modulo.nivel,
            imagenPath: modulo.imagenPath,
            color: modulo.color,
            bloqueado: modulo.bloqueado,
            descripcion: modulo.descripcion,
          );
        }
      } catch (e) {
        // Si falla, continuar con el siguiente módulo
        continue;
      }
    }
    notifyListeners();
  }

  /*
  Obtiene los niveles de un módulo específico desde Firestore
  y determina su estado basado en el progreso del usuario
  */
  Future<List<ModuleLevelInfo>> getModuleLevels(String moduleId) async {
    // Si ya están cargados, retornarlos
    if (_moduleLevels.containsKey(moduleId)) {
      return _moduleLevels[moduleId]!;
    }

    _isLoadingLevels = true;
    _errorMessageLevels = null;
    notifyListeners();

    try {
      // Obtener niveles desde Firestore
      final levelsData = await _firestoreService.getModuleLevels(moduleId);

      if (levelsData.isEmpty) {
        _errorMessageLevels = 'No se encontraron niveles para este módulo';
        return [];
      }

      // Obtener progreso del usuario para este módulo
      Map<String, Map<String, dynamic>> userProgress = {};
      if (_currentUserId != null) {
        userProgress = await _firestoreService.getUserLevelsProgress(
          _currentUserId!,
          moduleId,
        );
      }

      // Convertir datos de Firestore a ModuleLevelInfo y determinar estados
      // Primero crear todos los niveles sin estados finales
      final nivelesTemporales = levelsData.map((data) {
        final levelId = data['id']?.toString() ?? '';
        final levelProgress = userProgress[levelId];
        
        return _createModuleLevelInfoWithProgress(
          data,
          levelProgress,
          moduleId,
        );
      }).toList();

      // Ahora determinar estados considerando el orden y progreso
      final niveles = _determineLevelStates(nivelesTemporales, userProgress);

      // Guardar en caché
      _moduleLevels[moduleId] = niveles;
      _userProgress[moduleId] = userProgress;

      return niveles;
    } catch (e) {
      _errorMessageLevels = 'Error al cargar los niveles: $e';
      return [];
    } finally {
      _isLoadingLevels = false;
      notifyListeners();
    }
  }

  /*
  Crea un ModuleLevelInfo desde datos de Firestore
  */
  ModuleLevelInfo _createModuleLevelInfoWithProgress(
    Map<String, dynamic> data,
    Map<String, dynamic>? progress,
    String moduleId,
  ) {
    // Convertir orden de manera segura
    int ordenValue;
    try {
      if (data['orden'] is int) {
        ordenValue = data['orden'];
      } else if (data['orden'] is String) {
        ordenValue = int.parse(data['orden']);
      } else {
        ordenValue = 0;
      }
    } catch (e) {
      ordenValue = 0;
    }

    // Obtener estrellas del progreso
    int estrellasValue = 0;
    if (progress != null) {
      try {
        if (progress['estrellas'] is int) {
          estrellasValue = progress['estrellas'];
        } else if (progress['estrellas'] is String) {
          estrellasValue = int.parse(progress['estrellas']);
        }
      } catch (e) {
        estrellasValue = 0;
      }
    }

    // Parsear actividadData
    Map<String, dynamic>? actividadDataValue;
    try {
      if (data['actividadData'] != null) {
        actividadDataValue = data['actividadData'] as Map<String, dynamic>;
      }
    } catch (e) {
      actividadDataValue = null;
    }

    return ModuleLevelInfo(
      id: data['id']?.toString() ?? '',
      titulo: data['titulo']?.toString() ?? '',
      orden: ordenValue,
      pictogramaUrl: data['pictogramaUrl']?.toString(),
      videoUrl: data['videoUrl']?.toString(),
      actividadType: data['actividadType']?.toString() ?? 'simple_selection',
      actividadData: actividadDataValue,
      estrellas: estrellasValue,
      estado: StateOfStep.blocked, // Se determinará después
    );
  }

  /*
  Determina los estados de todos los niveles considerando el orden y progreso
  Reglas:
  - El primer nivel (orden = 1) siempre está inProgress si no está completado
  - Un nivel está completado si tiene progreso con estado 'completed' o estrellas > 0
  - Un nivel está bloqueado si el nivel anterior no está completado
  - Un nivel está inProgress si es el siguiente nivel después del último completado
  */
  List<ModuleLevelInfo> _determineLevelStates(
    List<ModuleLevelInfo> niveles,
    Map<String, Map<String, dynamic>> userProgress,
  ) {
    // Ordenar por orden
    niveles.sort((a, b) => a.orden.compareTo(b.orden));

    // Determinar estados
    for (int i = 0; i < niveles.length; i++) {
      final nivel = niveles[i];
      final levelId = nivel.id;
      final progress = userProgress[levelId];

      StateOfStep estado;

      // Si hay progreso, verificar estado
      if (progress != null) {
        final status = progress['status']?.toString()?.toLowerCase();
        final estrellas = progress['estrellas'] as int? ?? 0;
        
        if (status == 'completed' || estrellas > 0) {
          estado = StateOfStep.completed;
        } else if (status == 'in_progress' || status == 'inprogress') {
          estado = StateOfStep.inProgress;
        } else {
          // Si no hay estado claro pero hay progreso, considerar completado si tiene estrellas
          estado = estrellas > 0 ? StateOfStep.completed : StateOfStep.inProgress;
        }
      } else {
        // No hay progreso, determinar basado en niveles anteriores
        if (i == 0) {
          // Primer nivel siempre está en progreso
          estado = StateOfStep.inProgress;
        } else {
          // Verificar si el nivel anterior está completado
          final previousLevel = niveles[i - 1];
          if (previousLevel.estado == StateOfStep.completed) {
            estado = StateOfStep.inProgress;
          } else {
            estado = StateOfStep.blocked;
          }
        }
      }

      // Actualizar el estado del nivel
      niveles[i] = ModuleLevelInfo(
        id: nivel.id,
        titulo: nivel.titulo,
        orden: nivel.orden,
        pictogramaUrl: nivel.pictogramaUrl,
        videoUrl: nivel.videoUrl,
        actividadType: nivel.actividadType,
        actividadData: nivel.actividadData,
        estrellas: nivel.estrellas,
        estado: estado,
      );
    }

    return niveles;
  }

  /*
  Obtiene el progreso del usuario para un módulo específico
  */
  Future<Map<String, Map<String, dynamic>>> getUserProgress(String moduleId) async {
    if (_currentUserId == null) {
      return {};
    }

    // Si ya está en caché, retornarlo
    if (_userProgress.containsKey(moduleId)) {
      return _userProgress[moduleId]!;
    }

    try {
      final progress = await _firestoreService.getUserLevelsProgress(
        _currentUserId!,
        moduleId,
      );
      _userProgress[moduleId] = progress;
      return progress;
    } catch (e) {
      return {};
    }
  }

  /*
  Recarga los módulos desde Firestore
  */
  Future<void> reloadModules() async {
    _moduleLevels.clear();
    _userProgress.clear();
    await loadModules();
  }

  /*
  Recarga los niveles de un módulo específico
  */
  Future<void> reloadModuleLevels(String moduleId) async {
    _moduleLevels.remove(moduleId);
    _userProgress.remove(moduleId);
    await getModuleLevels(moduleId);
    notifyListeners();
  }

  /*
  Obtiene el título del módulo desde Firestore
  */
  Future<String> getModuleTitle(String moduleId) async {
    try {
      final moduleData = await _firestoreService.getModuleData(moduleId);
      if (moduleData != null) {
        return moduleData['titulo']?.toString() ?? 'Módulo de Aprendizaje';
      }
    } catch (e) {
      // Si falla, usar un título por defecto basado en el moduleId
      if (moduleId.contains('Higiene') || moduleId.contains('higiene')) {
        return 'Módulo de Higiene';
      } else if (moduleId.contains('alimentacion')) {
        return 'Módulo de Alimentación';
      } else if (moduleId.contains('socializacion')) {
        return 'Módulo de Socialización';
      }
    }
    return 'Módulo de Aprendizaje';
  }
}

