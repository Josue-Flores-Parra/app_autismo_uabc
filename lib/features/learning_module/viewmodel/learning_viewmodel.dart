import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
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

  // Nivel del usuario
  int _userLevel = 1;

  // Control de race conditions: evitar peticiones duplicadas simultáneas
  final Map<String, Future<List<ModuleLevelInfo>>> _pendingLevelLoads = {};

  // Pines de caché de imágenes por moduleId.
  // Cada pin mantiene una imagen viva en el ImageCache de Flutter
  // independientemente de si algún widget la está mostrando en ese momento.
  // Se liberan únicamente al recargar o al destruir el ViewModel.
  final Map<String, List<ImageStreamCompleter>> _imagePins = {};

  // Getters
  List<ModuloInfo> get modulos => _modulos;
  bool get isLoadingModules => _isLoadingModules;
  String? get errorMessageModules => _errorMessageModules;
  bool get isLoadingLevels => _isLoadingLevels;
  String? get errorMessageLevels => _errorMessageLevels;
  int get userLevel => _userLevel;

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
  Carga todos los módulos desde Firestore.
  Paraleliza la carga del nivel de usuario y la lista de módulos.
  */
  Future<void> loadModules() async {
    _isLoadingModules = true;
    _errorMessageModules = null;
    notifyListeners();

    try {
      // Cargar nivel del usuario y módulos en paralelo
      final results = await Future.wait([
        _firestoreService.getAllModules(),
        if (_currentUserId != null)
          _firestoreService.getUserLevel(_currentUserId!)
        else
          Future.value(1),
      ]);

      final modulesData = results[0] as List<Map<String, dynamic>>;
      _userLevel = results[1] as int;

      if (modulesData.isEmpty) {
        _errorMessageModules = 'No se encontraron módulos en Firestore';
        _modulos = [];
      } else {
        // Convertir datos de Firestore a objetos ModuloInfo
        _modulos = modulesData.map((data) {
          final modulo = ModuloInfo.fromFirestore(data, estrellas: 0);
          final nivelMinimo = modulo.nivel;
          final bloqueadoDesdeFirestore = data['bloqueado'] as bool? ?? false;
          final bloqueadoPorNivel = _userLevel < nivelMinimo;
          final estaBloqueado = bloqueadoDesdeFirestore || bloqueadoPorNivel;

          return ModuloInfo(
            id: modulo.id,
            titulo: modulo.titulo,
            estrellas: modulo.estrellas,
            nivel: modulo.nivel,
            imagenPath: modulo.imagenPath,
            lvlBackgroundImageUrl: modulo.lvlBackgroundImageUrl,
            color: modulo.color,
            bloqueado: estaBloqueado,
            descripcion: modulo.descripcion,
          );
        }).toList();

        // Cargar progreso de todos los módulos en paralelo
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
  Carga el progreso del usuario para todos los módulos en paralelo (Future.wait)
  y actualiza las estrellas de cada módulo.
  */
  Future<void> _loadModulesProgress() async {
    if (_currentUserId == null || _modulos.isEmpty) return;

    // Lanzar todas las peticiones de progreso en paralelo
    final progressFutures = _modulos.map(
      (modulo) => _firestoreService
          .getUserLevelsProgress(_currentUserId!, modulo.id)
          .catchError((_) => <String, Map<String, dynamic>>{}),
    );

    final progressResults = await Future.wait(progressFutures);

    // Aplicar resultados a cada módulo
    for (int i = 0; i < _modulos.length; i++) {
      final modulo = _modulos[i];
      final progress = progressResults[i];

      int totalStars = 0;
      progress.forEach((_, levelProgress) {
        totalStars += (levelProgress['estrellas'] as int? ?? 0);
      });

      final bloqueadoPorNivel = _userLevel < modulo.nivel;
      final estaBloqueado = modulo.bloqueado || bloqueadoPorNivel;

      _modulos[i] = ModuloInfo(
        id: modulo.id,
        titulo: modulo.titulo,
        estrellas: totalStars,
        nivel: modulo.nivel,
        imagenPath: modulo.imagenPath,
        lvlBackgroundImageUrl: modulo.lvlBackgroundImageUrl,
        color: modulo.color,
        bloqueado: estaBloqueado,
        descripcion: modulo.descripcion,
      );
    }
    notifyListeners();
  }

  /*
  Obtiene los niveles de un módulo específico desde Firestore.
  Protege contra race conditions: si ya hay una carga en curso para el mismo
  moduleId, reutiliza el mismo Future en lugar de lanzar una petición duplicada.
  */
  Future<List<ModuleLevelInfo>> getModuleLevels(String moduleId, {bool forceReload = false}) async {
    // Si ya están en caché y no se fuerza recarga, retornarlos inmediatamente
    if (!forceReload && _moduleLevels.containsKey(moduleId)) {
      return _moduleLevels[moduleId]!;
    }

    // Si ya hay una carga en curso para este moduleId, reutilizar ese Future
    // para evitar peticiones duplicadas (race condition al pulsar un nodo rápido)
    if (_pendingLevelLoads.containsKey(moduleId)) {
      return _pendingLevelLoads[moduleId]!;
    }

    // Registrar el Future antes de await para que llamadas concurrentes lo reutilicen
    final future = _fetchModuleLevels(moduleId);
    _pendingLevelLoads[moduleId] = future;

    try {
      return await future;
    } finally {
      _pendingLevelLoads.remove(moduleId);
    }
  }

  /*
  Realiza la carga real de niveles + progreso en paralelo con Future.wait
  */
  Future<List<ModuleLevelInfo>> _fetchModuleLevels(String moduleId) async {
    _isLoadingLevels = true;
    _errorMessageLevels = null;
    notifyListeners();

    try {
      // Cargar niveles y progreso del usuario en paralelo
      final results = await Future.wait([
        _firestoreService.getModuleLevels(moduleId),
        if (_currentUserId != null)
          _firestoreService.getUserLevelsProgress(_currentUserId!, moduleId)
        else
          Future.value(<String, Map<String, dynamic>>{}),
      ]);

      final levelsData = results[0] as List<Map<String, dynamic>>;
      final userProgress = results[1] as Map<String, Map<String, dynamic>>;

      if (levelsData.isEmpty) {
        _errorMessageLevels = 'No se encontraron niveles para este módulo';
        return [];
      }

      // Convertir datos y determinar estados
      final nivelesTemporales = levelsData.map((data) {
        final levelId = data['id']?.toString() ?? '';
        return _createModuleLevelInfoWithProgress(
          data,
          userProgress[levelId],
          moduleId,
        );
      }).toList();

      final niveles = _determineLevelStates(nivelesTemporales, userProgress);

      // Guardar en caché y fijar imágenes en el ImageCache para todo el módulo
      _moduleLevels[moduleId] = niveles;
      _userProgress[moduleId] = userProgress;
      _pinLevelImages(moduleId, niveles);

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
  Precarga en segundo plano los niveles de un módulo (sin afectar el estado de carga de la UI).
  Útil para anticipar que el usuario va a entrar a un módulo.
  No lanza excepciones — falla silenciosamente.
  */
  void prefetchModuleLevels(String moduleId) {
    if (_moduleLevels.containsKey(moduleId)) return; // Ya en caché
    if (_pendingLevelLoads.containsKey(moduleId)) return; // Ya cargando

    // Lanzar sin await — corre en background
    getModuleLevels(moduleId).catchError((_) => <ModuleLevelInfo>[]);
  }

  /*
  Helper para parsear actividadType desde Firestore.
  Trata null, cadenas vacías y la cadena "null" como null.
  */
  String? _parseActividadType(dynamic actividadType) {
    if (actividadType == null) return null;
    final String str = actividadType.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'null') return null;
    return str;
  }

  /*
  Crea un ModuleLevelInfo desde datos de Firestore
  */
  ModuleLevelInfo _createModuleLevelInfoWithProgress(
    Map<String, dynamic> data,
    Map<String, dynamic>? progress,
    String moduleId,
  ) {
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
      audioUrl: data['audioUrl']?.toString(),
      actividadType: _parseActividadType(data['actividadType']),
      actividadData: actividadDataValue,
      estrellas: estrellasValue,
      estado: StateOfStep.blocked,
    );
  }

  /*
  Determina los estados de todos los niveles considerando el orden y progreso.
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
    niveles.sort((a, b) => a.orden.compareTo(b.orden));

    for (int i = 0; i < niveles.length; i++) {
      final nivel = niveles[i];
      final progress = userProgress[nivel.id];

      StateOfStep estado;

      if (progress != null) {
        final status = progress['status']?.toString().toLowerCase();
        final estrellas = progress['estrellas'] as int? ?? 0;

        if (status == 'completed' || estrellas > 0) {
          estado = StateOfStep.completed;
        } else if (status == 'in_progress' || status == 'inprogress') {
          estado = StateOfStep.inProgress;
        } else {
          estado = estrellas > 0 ? StateOfStep.completed : StateOfStep.inProgress;
        }
      } else {
        if (i == 0) {
          estado = StateOfStep.inProgress;
        } else {
          final previousLevel = niveles[i - 1];
          estado = previousLevel.estado == StateOfStep.completed
              ? StateOfStep.inProgress
              : StateOfStep.blocked;
        }
      }

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
  Obtiene el progreso del usuario para un módulo específico.
  Usa caché si está disponible.
  */
  Future<Map<String, Map<String, dynamic>>> getUserProgress(String moduleId) async {
    if (_currentUserId == null) return {};
    if (_userProgress.containsKey(moduleId)) return _userProgress[moduleId]!;

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
  Recarga los módulos desde Firestore limpiando toda la caché
  */
  Future<void> reloadModules() async {
    _releaseAllPins();
    _moduleLevels.clear();
    _userProgress.clear();
    _pendingLevelLoads.clear();
    await loadModules();
  }

  /*
  Recarga los niveles de un módulo específico
  */
  Future<void> reloadModuleLevels(String moduleId) async {
    _releasePinsForModule(moduleId);
    _moduleLevels.remove(moduleId);
    _userProgress.remove(moduleId);
    _pendingLevelLoads.remove(moduleId);
    await getModuleLevels(moduleId);
    notifyListeners();
  }

  /*
  Obtiene el título del módulo.
  Primero busca en la caché local de módulos para evitar una petición extra a Firestore.
  Solo consulta Firestore si no está disponible en caché.
  */
  Future<String> getModuleTitle(String moduleId) async {
    // Buscar en caché primero — evita una petición a Firestore
    final cached = _modulos.where((m) => m.id == moduleId).firstOrNull;
    if (cached != null && cached.titulo.isNotEmpty) {
      return cached.titulo;
    }

    // Fallback: consultar Firestore solo si no estaba en caché
    try {
      final moduleData = await _firestoreService.getModuleData(moduleId);
      if (moduleData != null) {
        return moduleData['titulo']?.toString() ?? 'Módulo de Aprendizaje';
      }
    } catch (e) {
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

  // ─────────────────────────────────────────────────────────────────────────
  // Gestión de pines del ImageCache
  // ─────────────────────────────────────────────────────────────────────────

  /*
  Fija en el ImageCache de Flutter todas las imágenes de red de los niveles
  de un módulo. Mientras el pin esté activo, Flutter nunca desechara esas
  imágenes aunque ningún widget las esté mostrando — esto es lo que garantiza
  que las portadas sigan disponibles al regresar del LevelPlayScreen.

  Usa ImageCache.putIfAbsent, la API oficial de Flutter para keep-alives
  (la misma que usa precacheImage internamente).
  */
  void _pinLevelImages(String moduleId, List<ModuleLevelInfo> levels) {
    // Soltar pines anteriores del mismo módulo antes de crear los nuevos
    _releasePinsForModule(moduleId);

    final pins = <ImageStreamCompleter>[];

    for (final level in levels) {
      // Portada del nivel
      _tryPin(level.pictogramaUrl, pins);

      // Imagen dentro de actividadData
      _tryPin(level.actividadData?['pictogramaUrl'] as String?, pins);

      // Opciones planas (simple_selection)
      final options = level.actividadData?['options'];
      if (options is List) {
        for (final opt in options) {
          if (opt is Map) _tryPin(opt['imagePath'] as String?, pins);
        }
      }

      // Preguntas múltiples (simple_selection con 'questions')
      final questions = level.actividadData?['questions'];
      if (questions is List) {
        for (final q in questions) {
          if (q is Map) {
            final qOptions = q['options'];
            if (qOptions is List) {
              for (final opt in qOptions) {
                if (opt is Map) _tryPin(opt['imagePath'] as String?, pins);
              }
            }
          }
        }
      }
    }

    if (pins.isNotEmpty) {
      _imagePins[moduleId] = pins;
    }
  }

  /*
  Intenta fijar una URL en el ImageCache y agrega el completer a [pins].
  Si la URL es nula, vacía o no es HTTP, no hace nada.
  */
  void _tryPin(String? url, List<ImageStreamCompleter> pins) {
    if (url == null || url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) return;

    try {
      final provider = NetworkImage(url);
      // putIfAbsent devuelve el completer existente o crea uno nuevo y lo añade
      // al caché. Mientras guardemos este completer, la imagen no será evictada.
      final completer = PaintingBinding.instance.imageCache.putIfAbsent(
        provider,
        () => provider.loadImage(
          provider,
          PaintingBinding.instance.instantiateImageCodecWithSize,
        ),
      );
      if (completer != null) pins.add(completer);
    } catch (_) {
      // Fallo silencioso — nunca interrumpir la UI por un pin fallido
    }
  }

  /*
  Libera todos los pines del ImageCache para un módulo específico.
  Llamar al recargar los niveles del módulo.
  */
  void _releasePinsForModule(String moduleId) {
    _imagePins.remove(moduleId);
    // Al eliminar las referencias a los ImageStreamCompleter, el ImageCache
    // queda libre de evictarlos si necesita memoria — comportamiento correcto.
  }

  /*
  Libera todos los pines de todos los módulos.
  Llamar al recargar módulos o al destruir el ViewModel.
  */
  void _releaseAllPins() {
    _imagePins.clear();
  }

  @override
  void dispose() {
    _releaseAllPins();
    super.dispose();
  }
}

