import 'package:flutter/foundation.dart';
import '../model/avatar_models.dart';
import '../data/avatar_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/firestore_services.dart';

/*
VIEWMODEL DEL AVATAR
Maneja el estado y la lógica de presentación del avatar
Usa ChangeNotifier para notificar cambios a la UI
*/

// El campo avatarConfig en el documento de usuario (Firestore) ya existía;
// este viewmodel lo reutiliza para leer y persistir skin, expresión,
// accesorio, fondo, nombre, felicidad, energía, monedas y accesorios
// desbloqueados.

class AvatarViewModel extends ChangeNotifier {
  /// Felicidad que suma completar una actividad con éxito.
  static const int _felicidadPorExito = 5;

  /// Felicidad que suma intentarlo aunque no se logre.
  static const int _felicidadPorIntento = 1;

  /// Felicidad que suma repasar una modalidad ya completada antes.
  static const int _felicidadPorRepaso = 1;

  /// Energía que consume jugar una actividad por primera vez.
  static const int _energiaPorActividad = 4;

  /// Energía que devuelve repasar una modalidad ya completada: el repaso no
  /// cansa al personaje, lo ayuda a descansar.
  static const int _energiaPorRepaso = 3;

  /// Minutos de descanso que devuelven un punto de energía.
  static const int _minutosPorPuntoDeEnergia = 6;

  /// Minutos sin actividad que bajan un punto de felicidad. Igual al ritmo
  /// de recuperacion de energia: con 15 min casi no se notaba el cambio en
  /// una sesion de uso normal.
  static const int _minutosPorPuntoDeFelicidadPerdida = 6;

  /// Piso de la felicidad por simple paso del tiempo: el personaje se pone
  /// mas serio si no se le presta atencion, pero nunca llega a triste solo
  /// por inactividad. Fallar o no jugar no debe sentirse como un castigo.
  static const int _felicidadMinimaPorInactividad = 30;

  // Estado privado
  bool _showEditPanel = false;
  late AvatarEstado _currentEstado;

  // Estado con el que se construyó el viewmodel. Sirve para volver a empezar
  // cuando entra una cuenta distinta en el mismo dispositivo.
  final AvatarEstado _estadoInicial;

  // uid cuya configuración está cargada en memoria. Mientras sea null no se
  // escribe nada en Firestore: guardar antes de leer sobrescribía las monedas
  // del usuario con los valores por defecto.
  String? _loadedUid;
  bool _isLoading = false;

  // Momento del último cálculo de energía, persistido junto al avatar.
  DateTime? _energiaActualizadaEn;

  // Datos del Repository (cached)
  late final List<SkinInfo> _availableSkins;
  late final List<AccesorioGeneral> _availableAccesorios;
  late final List<FondoInfo> _availableFondos;

  final FirestoreService _firestoreService = FirestoreService();

  // Constructor
  AvatarViewModel(AvatarEstado initialEstado) : _estadoInicial = initialEstado {
    _currentEstado = initialEstado;
    // Cargar datos del repository
    _availableSkins = AvatarRepository.obtenerSkinsDisponibles();
    _availableAccesorios = AvatarRepository.obtenerAccesoriosGenerales();
    _availableFondos = AvatarRepository.obtenerFondosDisponibles();
  }

  Future<void> initialize() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _isLoading) return;
    if (_loadedUid == uid) {
      return; // Ya cargado para esta cuenta.
    }

    _isLoading = true;
    try {
      if (_loadedUid != null) {
        // Cambió la cuenta: no heredar monedas ni accesorios de la anterior.
        _currentEstado = _estadoInicial;
        _energiaActualizadaEn = null;
      }
      await loadAvatarConfigFromFirestore();
    } finally {
      _isLoading = false;
    }
  }

  Future<void> saveAvatarConfigToFirestore() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in.');
      }
      final userId = user.uid;

      // Nunca escribir sobre una configuración que todavía no se ha leído.
      if (_loadedUid != userId) return;

      final giveCurrentDataToAvatarConfigMap = _currentEstado.toConfigMap();
      giveCurrentDataToAvatarConfigMap['energiaActualizadaEn'] =
          (_energiaActualizadaEn ?? DateTime.now()).toIso8601String();

      // Guardar en Firestore
      try {
        await _firestoreService.setUserData(userId, {
          'avatarConfig': giveCurrentDataToAvatarConfigMap,
        });
      } catch (e) {
        throw Exception('Error saving avatar config to Firestore: $e');
      }
    } catch (e) {
      throw Exception('Error in saveAvatarConfigToFirestore: $e');
    }
  }

  /* Funcion para cargar el estado actual del avatar desde Firestore
  */

  Future<void> loadAvatarConfigFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final userId = user.uid;

    try {
      final userData = await _firestoreService.getUserData(userId);

      final nombreEnFirestore = userData?['name'] as String?;

      if (userData != null && userData.containsKey('avatarConfig')) {
        final configMap = userData['avatarConfig'] as Map<String, dynamic>;

        final skinNombre = configMap['skinActual'] as String?;
        final expresionPath = configMap['expresionActual'] as String?;
        final accesorioActualPath = configMap['accesorioActualPath'] as String?;
        final backgroundPath = configMap['backgroundActual'] as String?;
        final nombre = configMap['nombre'] as String?;
        final felicidad = configMap['felicidad'] as int?;
        final energia = configMap['energia'] as int?;
        final monedas = configMap['monedas'] as int?;
        final desbloqueadosGuardados =
            (configMap['accesoriosDesbloqueados'] as List?)
                ?.cast<String>()
                .toSet();
        final skinsDesbloqueadasGuardadas =
            (configMap['skinsDesbloqueadas'] as List?)?.cast<String>().toSet();
        final fondosDesbloqueadosGuardados =
            (configMap['fondosDesbloqueados'] as List?)
                ?.cast<String>()
                .toSet();

        final skinActual = _availableSkins.firstWhere(
          (s) => s.nombre == skinNombre,
          orElse: () => _availableSkins.first,
        );

        AccesorioGeneral? accesorioActual;
        if (accesorioActualPath != null) {
          try {
            accesorioActual = _availableAccesorios.firstWhere(
              (a) => a.imagenPath == accesorioActualPath,
            );
          } catch (e) {
            accesorioActual = null;
          }
        }

        // Si no hay nombre en avatarConfig o es el marcador que dejaban las
        // cuentas antiguas, usar el nombre de la cuenta (displayName o
        // Firestore "name") como en Módulos.
        final nombreFinal = !_esNombreSinDefinir(nombre)
            ? nombre!
            : (user.displayName?.trim().isNotEmpty == true
                  ? user.displayName!
                  : (nombreEnFirestore?.trim().isNotEmpty == true
                        ? nombreEnFirestore!
                        : _currentEstado.nombre));

        _energiaActualizadaEn = _parseFecha(configMap['energiaActualizadaEn']);

        // Cuentas de antes de que skins y fondos tuvieran costo no traen
        // estas dos listas: se desbloquea ahi mismo lo que ya tenian puesto,
        // para no quitarle a nadie algo que ya estaba usando.
        final skinsDesbloqueadasFinal =
            skinsDesbloqueadasGuardadas ??
            ({..._currentEstado.skinsDesbloqueadas, skinActual.nombre});
        final fondosDesbloqueadosFinal =
            fondosDesbloqueadosGuardados ??
            ({
              ..._currentEstado.fondosDesbloqueados,
              if (backgroundPath != null) backgroundPath,
            });

        _currentEstado = _currentEstado.copyWith(
          skinActual: skinActual,
          expresionActual: expresionPath,
          accesorioActual: accesorioActual,
          backgroundActual: backgroundPath ?? _currentEstado.backgroundActual,
          nombre: nombreFinal,
          felicidad: _felicidadConTiempo(felicidad ?? _currentEstado.felicidad),
          energia: _energiaConDescanso(energia ?? _currentEstado.energia),
          monedas: monedas ?? _currentEstado.monedas,
          accesoriosDesbloqueados:
              desbloqueadosGuardados ?? _currentEstado.accesoriosDesbloqueados,
          skinsDesbloqueadas: skinsDesbloqueadasFinal,
          fondosDesbloqueados: fondosDesbloqueadosFinal,
        );

        // El descanso ya quedó aplicado en el estado, así que la marca de
        // tiempo avanza para no volver a contarlo en la siguiente carga.
        _energiaActualizadaEn = DateTime.now();
        _loadedUid = userId;
        notifyListeners();
      } else {
        // Usuario nuevo o sin avatarConfig: usar nombre de la cuenta (como en Módulos).
        final nombreAUsar = user.displayName?.trim().isNotEmpty == true
            ? user.displayName!
            : (nombreEnFirestore?.trim().isNotEmpty == true
                  ? nombreEnFirestore!
                  : null);
        _loadedUid = userId;
        // Solo se toma el nombre de la cuenta si el de memoria sigue siendo
        // el valor de arranque; un nombre elegido por el usuario se respeta.
        final sinNombrePropio =
            _esNombreSinDefinir(_currentEstado.nombre) ||
            _currentEstado.nombre == AvatarEstado.nombrePorDefecto;
        if (nombreAUsar != null && sinNombrePropio) {
          _currentEstado = _currentEstado.copyWith(nombre: nombreAUsar);
          notifyListeners();
          await saveAvatarConfigToFirestore();
        } else {
          notifyListeners();
        }
      }
    } catch (_) {
      // Una lectura fallida deja _loadedUid en null para reintentar más tarde
      // y para que ningún guardado pise la configuración remota.
    }
  }

  // Getters públicos
  bool get showEditPanel => _showEditPanel;
  AvatarEstado get currentEstado => _currentEstado;

  /// `true` cuando el estado en memoria ya es el de la cuenta actual.
  /// Mientras sea `false`, la pantalla no debe mostrar cifras: serían el
  /// marcador de arranque y no datos del usuario.
  bool get isLoaded => _loadedUid != null;

  // Getters para datos del Repository
  List<SkinInfo> get availableSkins => _availableSkins;
  List<AccesorioGeneral> get availableAccesorios => _availableAccesorios;
  List<FondoInfo> get availableFondos => _availableFondos;

  /*
  Alterna la visibilidad del panel de edición
  */
  void toggleEditPanel() {
    _showEditPanel = !_showEditPanel;
    notifyListeners();
  }

  /*
  Actualiza la skin actual del avatar
  Automáticamente limpia la expresión cuando cambias de skin
  */
  Future<void> updateSkin(SkinInfo newSkin) async {
    _currentEstado = _currentEstado.copyWith(
      skinActual: newSkin,
      resetExpresion: true, // Limpiar expresión al cambiar skin
    );
    notifyListeners();
    await saveAvatarConfigToFirestore();
  }

  /*
  Actualiza la expresión del avatar
  Si se pasa null, limpia la expresión actual
  */
  Future<void> updateExpresion(String? expresion) async {
    if (expresion == null) {
      _currentEstado = _currentEstado.copyWith(resetExpresion: true);
    } else {
      _currentEstado = _currentEstado.copyWith(expresionActual: expresion);
    }
    notifyListeners();
    await saveAvatarConfigToFirestore();
  }

  /*
  Actualiza el accesorio del avatar
  Si se pasa null, quita el accesorio actual
  */
  Future<void> updateAccesorio(AccesorioGeneral? accesorio) async {
    if (accesorio == null) {
      _currentEstado = _currentEstado.copyWith(resetAccesorio: true);
    } else {
      _currentEstado = _currentEstado.copyWith(accesorioActual: accesorio);
    }
    notifyListeners();
    await saveAvatarConfigToFirestore();
  }

  /*
  Actualiza el background del avatar
  */
  Future<void> updateBackground(String background) async {
    _currentEstado = _currentEstado.copyWith(backgroundActual: background);
    notifyListeners();
    await saveAvatarConfigToFirestore();
  }

  /*
  Actualiza el nombre del avatar
  */
  Future<void> updateNombre(String nuevoNombre) async {
    await initialize();
    _currentEstado = _currentEstado.copyWith(nombre: nuevoNombre);
    notifyListeners();
    await saveAvatarConfigToFirestore();
  }

  /// Sincroniza el nombre del avatar con el displayName del usuario.
  /// Si falla el guardado remoto, al menos mantiene el estado local actualizado.
  Future<void> updateNombreDesdeDisplayName(String nuevoNombre) async {
    _currentEstado = _currentEstado.copyWith(nombre: nuevoNombre);
    notifyListeners();
    try {
      await saveAvatarConfigToFirestore();
    } catch (_) {
      // Ignorar, el estado local ya refleja el cambio.
    }
  }

  /*
  Actualiza la felicidad del avatar (0-100)
  */
  Future<void> updateFelicidad(int nuevaFelicidad) async {
    if (nuevaFelicidad < 0 || nuevaFelicidad > 100) {
      throw ArgumentError('La felicidad debe estar entre 0 y 100');
    }
    _currentEstado = _currentEstado.copyWith(felicidad: nuevaFelicidad);
    notifyListeners();
    await saveAvatarConfigToFirestore();
  }

  /*
  Actualiza la energía del avatar (0-100)
  */
  Future<void> updateEnergia(int nuevaEnergia) async {
    if (nuevaEnergia < 0 || nuevaEnergia > 100) {
      throw ArgumentError('La energía debe estar entre 0 y 100');
    }
    _currentEstado = _currentEstado.copyWith(energia: nuevaEnergia);
    _energiaActualizadaEn = DateTime.now();
    notifyListeners();
    await saveAvatarConfigToFirestore();
  }

  /*
  Aplica el efecto de una actividad terminada sobre el avatar: sube la
  felicidad, consume (o devuelve, si es repaso) energía y suma las monedas
  ganadas. Es un único guardado para que las tres estadísticas nunca queden
  desincronizadas entre sí.

  [esRepaso] marca una modalidad que el nivel ya había completado antes: en
  vez de cansar al personaje, un repaso lo ayuda a descansar (energía sube en
  vez de bajar) y da una recompensa menor en monedas, para que repasar valga
  la pena sin igualar la primera vez.

  Devuelve cuánto subió/bajó cada estadística, para que la pantalla que llamó
  pueda mostrarlo (ej. "+5 felicidad, +3 energía").
  */
  Future<AvatarActivityDelta> registrarActividad({
    required bool success,
    int monedas = 0,
    bool esRepaso = false,
  }) async {
    await initialize();

    final felicidadDelta = esRepaso
        ? _felicidadPorRepaso
        : (success ? _felicidadPorExito : _felicidadPorIntento);
    final energiaDelta = esRepaso ? _energiaPorRepaso : -_energiaPorActividad;

    final felicidad = _felicidadConTiempo(_currentEstado.felicidad) + felicidadDelta;
    final energia = _energiaConDescanso(_currentEstado.energia) + energiaDelta;

    _currentEstado = _currentEstado.copyWith(
      felicidad: felicidad.clamp(0, 100),
      energia: energia.clamp(0, 100),
      monedas: _currentEstado.monedas + monedas,
    );
    _energiaActualizadaEn = DateTime.now();
    notifyListeners();
    await saveAvatarConfigToFirestore();
    return AvatarActivityDelta(felicidad: felicidadDelta, energia: energiaDelta);
  }

  /*
  Verifica si un accesorio está desbloqueado
  */
  bool isAccesorioDesbloqueado(String nombreAccesorio) {
    return _currentEstado.accesoriosDesbloqueados.contains(nombreAccesorio);
  }

  /*
  Intenta desbloquear un accesorio con monedas
  Retorna true si se desbloqueó exitosamente, false si no hay suficientes monedas
  */
  Future<bool> desbloquearAccesorio(AccesorioGeneral accesorio) async {
    await initialize();

    // Verificar si ya está desbloqueado
    if (isAccesorioDesbloqueado(accesorio.nombre)) {
      return true; // Ya está desbloqueado
    }

    // Verificar si tiene suficientes monedas
    if (_currentEstado.monedas < accesorio.costoMonedas) {
      return false; // No hay suficientes monedas
    }

    // Desbloquear el accesorio
    final nuevasMonedas = _currentEstado.monedas - accesorio.costoMonedas;
    final nuevosDesbloqueados = Set<String>.from(
      _currentEstado.accesoriosDesbloqueados,
    )..add(accesorio.nombre);

    _currentEstado = _currentEstado.copyWith(
      monedas: nuevasMonedas,
      accesoriosDesbloqueados: nuevosDesbloqueados,
    );
    notifyListeners();
    await saveAvatarConfigToFirestore();
    return true;
  }

  /*
  Verifica si una skin está desbloqueada
  */
  bool isSkinDesbloqueada(String nombreSkin) {
    return _currentEstado.skinsDesbloqueadas.contains(nombreSkin);
  }

  /*
  Intenta desbloquear una skin con monedas.
  Retorna true si se desbloqueó (o ya lo estaba), false si faltan monedas.
  */
  Future<bool> desbloquearSkin(SkinInfo skin) async {
    await initialize();

    if (isSkinDesbloqueada(skin.nombre)) return true;
    if (_currentEstado.monedas < skin.costoMonedas) return false;

    final nuevasMonedas = _currentEstado.monedas - skin.costoMonedas;
    final nuevasDesbloqueadas = Set<String>.from(
      _currentEstado.skinsDesbloqueadas,
    )..add(skin.nombre);

    _currentEstado = _currentEstado.copyWith(
      monedas: nuevasMonedas,
      skinsDesbloqueadas: nuevasDesbloqueadas,
    );
    notifyListeners();
    await saveAvatarConfigToFirestore();
    return true;
  }

  /*
  Verifica si un fondo está desbloqueado
  */
  bool isFondoDesbloqueado(String path) {
    return _currentEstado.fondosDesbloqueados.contains(path);
  }

  /*
  Intenta desbloquear un fondo con monedas.
  Retorna true si se desbloqueó (o ya lo estaba), false si faltan monedas.
  */
  Future<bool> desbloquearFondo(FondoInfo fondo) async {
    await initialize();

    if (isFondoDesbloqueado(fondo.path)) return true;
    if (_currentEstado.monedas < fondo.costoMonedas) return false;

    final nuevasMonedas = _currentEstado.monedas - fondo.costoMonedas;
    final nuevosDesbloqueados = Set<String>.from(
      _currentEstado.fondosDesbloqueados,
    )..add(fondo.path);

    _currentEstado = _currentEstado.copyWith(
      monedas: nuevasMonedas,
      fondosDesbloqueados: nuevosDesbloqueados,
    );
    notifyListeners();
    await saveAvatarConfigToFirestore();
    return true;
  }

  /*
  Agrega monedas al usuario (por completar actividades, etc.)
  */
  Future<void> agregarMonedas(int cantidad) async {
    await initialize();
    _currentEstado = _currentEstado.copyWith(
      monedas: _currentEstado.monedas + cantidad,
    );
    notifyListeners();
    await saveAvatarConfigToFirestore();
  }

  /*
  Resetea el avatar a un estado específico
  Útil para reiniciar la personalización
  */
  Future<void> resetEstado(AvatarEstado nuevoEstado) async {
    _currentEstado = nuevoEstado;
    _showEditPanel = false;
    notifyListeners();
    await saveAvatarConfigToFirestore();
  }

  /*
  Devuelve la energía ya recuperada por el tiempo transcurrido desde el último
  cálculo. Sin esto la energía solo bajaría y quedaría clavada en cero.
  */
  int _energiaConDescanso(int energiaGuardada) {
    final desde = _energiaActualizadaEn;
    if (desde == null) return energiaGuardada.clamp(0, 100);

    final minutos = DateTime.now().difference(desde).inMinutes;
    if (minutos <= 0) return energiaGuardada.clamp(0, 100);

    final recuperada = minutos ~/ _minutosPorPuntoDeEnergia;
    return (energiaGuardada + recuperada).clamp(0, 100);
  }

  /*
  Baja la felicidad segun el tiempo sin actividad, con piso en
  [_felicidadMinimaPorInactividad]: sin esto la felicidad solo sube (por exito
  o intento) y nunca refleja que el personaje lleva tiempo sin atencion.
  */
  int _felicidadConTiempo(int felicidadGuardada) {
    final desde = _energiaActualizadaEn;
    if (desde == null || felicidadGuardada <= _felicidadMinimaPorInactividad) {
      return felicidadGuardada.clamp(0, 100);
    }

    final minutos = DateTime.now().difference(desde).inMinutes;
    if (minutos <= 0) return felicidadGuardada.clamp(0, 100);

    final perdida = minutos ~/ _minutosPorPuntoDeFelicidadPerdida;
    return (felicidadGuardada - perdida).clamp(
      _felicidadMinimaPorInactividad,
      100,
    );
  }

  DateTime? _parseFecha(dynamic value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

  /// Un nombre guardado cuenta como no definido si esta vacio o si es el
  /// marcador literal `nombre` que dejaban las cuentas antiguas.
  bool _esNombreSinDefinir(String? nombre) {
    if (nombre == null) return true;
    final limpio = nombre.trim();
    return limpio.isEmpty || limpio == 'nombre';
  }
}

/// Cuanto subio/bajo cada estadistica al registrar una actividad. Sirve para
/// que la pantalla que llamo a [AvatarViewModel.registrarActividad] muestre
/// el efecto real, no solo las monedas.
class AvatarActivityDelta {
  final int felicidad;
  final int energia;

  const AvatarActivityDelta({required this.felicidad, required this.energia});
}
