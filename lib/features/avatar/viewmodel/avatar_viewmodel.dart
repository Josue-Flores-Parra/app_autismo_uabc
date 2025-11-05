import 'package:flutter/foundation.dart';
import '../model/avatar_models.dart';
import '../data/avatar_repository.dart';

// nuevos imports para poder basarme en el user model y firestore
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/firestore_services.dart';

/*
VIEWMODEL DEL AVATAR
Maneja el estado y la lógica de presentación del avatar
Usa ChangeNotifier para notificar cambios a la UI
*/

/* Nuevas notas respecot a la issue #63: *
 - En el user model .dart archivo, ya venía un parametro que alguno de nuestros 
 compañeros agregó llamado avatarConfig, el cual ya genera cumplimiento con una 
 de las peticiones de la issue, que es guardar la configuración del avatar en el
 perfil del usuario en Firestore. Así que opté por dejar esa. 

 -- Creamos una nueva función asíncrona llamada saveAvatarConfigToFirestore()
    dentro del AvatarViewModel, la cual obtiene el usuario actual de FirebaseAuth,
    construye un mapa con la configuración actual del avatar y lo guarda en 
    Firestore usando el FirestoreService ya existente.

    -- Creamos una función que, cuando el usuario se logea, lee la configuración del
    avatar desde Firestore y la aplica al estado del AvatarViewModel. 


*/

class AvatarViewModel
    extends ChangeNotifier {
  // Estado privado
  bool _showEditPanel = false;
  late AvatarEstado _currentEstado;

  // Datos del Repository (cached)
  late final List<SkinInfo>
  _availableSkins;
  late final List<AccesorioGeneral>
  _availableAccesorios;
  late final List<String>
  _availableBackgrounds;

  /* Nuevo AÑADIDO issue #63
  Método para guardar la configuración del avatar en Firestore
  */

  final FirestoreService
  _firestoreService =
      FirestoreService();

  // Constructor
  AvatarViewModel(
    AvatarEstado initialEstado,
  ) {
    _currentEstado = initialEstado;
    // Cargar datos del repository
    _availableSkins =
        AvatarRepository.obtenerSkinsDisponibles();
    _availableAccesorios =
        AvatarRepository.obtenerAccesoriosGenerales();
    _availableBackgrounds =
        AvatarRepository.obtenerBackgroundsDisponibles();
  }

  Future<void> initialize() async {
    await loadAvatarConfigFromFirestore();
  }

  Future<void>
  saveAvatarConfigToFirestore() async {
    try {
      final User? user = FirebaseAuth
          .instance
          .currentUser;
      if (user == null) {
        throw Exception(
          'No user is currently signed in.',
        );
      }
      final userId = user.uid;

      final giveCurrentDataToAvatarConfigMap = {
        'nombre': _currentEstado.nombre,
        'felicidad':
            _currentEstado.felicidad,
        'energia':
            _currentEstado.energia,
        'skinActual': _currentEstado
            .skinActual
            .nombre,
        'expresionActual':
            _currentEstado
                .expresionActual,
        'accesorioActualPath':
            _currentEstado
                .accesorioActual
                ?.imagenPath,
        'backgroundActual':
            _currentEstado
                .backgroundActual,
        'monedas':
            _currentEstado.monedas,
        'accesoriosDesbloqueados':
            _currentEstado
                .accesoriosDesbloqueados
                .toList(),
      };

      // Guardar en Firestore
      try {
        await _firestoreService
            .setUserData(userId, {
              'avatarConfig':
                  giveCurrentDataToAvatarConfigMap,
            });
        print(
          'Avatar config saved YES.',
        );
      } catch (e) {
        throw Exception(
          'Error saving avatar config to Firestore: $e',
        );
      }
    } catch (e) {
      throw Exception(
        'Error in saveAvatarConfigToFirestore: $e',
      );
    }
  }

  /* Funcion para cargar el estado actual del avatar desde Firestore
  */

  Future<void>
  loadAvatarConfigFromFirestore() async {
    final user = FirebaseAuth
        .instance
        .currentUser;

    if (user == null) {
      print(
        'Info: No hay usuario logueado para cargar avatar.',
      );
      return;
    }

    final userId = user.uid;

    try {
      final userData =
          await _firestoreService
              .getUserData(userId);

      if (userData != null &&
          userData.containsKey(
            'avatarConfig',
          )) {
        final configMap =
            userData['avatarConfig']
                as Map<String, dynamic>;

        final skinNombre =
            configMap['skinActual']
                as String?;
        final expresionPath =
            configMap['expresionActual']
                as String?;
        final accesorioActualPath =
            configMap['accesorioActualPath']
                as String?;
        final backgroundPath =
            configMap['backgroundActual']
                as String?;
        final nombre =
            configMap['nombre']
                as String?;
        final felicidad =
            configMap['felicidad']
                as int?;
        final energia =
            configMap['energia']
                as int?;
        final monedas =
            configMap['monedas']
                as int?;
        final desbloqueadosGuardados =
            (configMap['accesoriosDesbloqueados']
                    as List?)
                ?.cast<String>()
                .toSet();

        final skinActual =
            _availableSkins.firstWhere(
              (s) =>
                  s.nombre ==
                  skinNombre,
              orElse: () =>
                  _availableSkins.first,
            );

        AccesorioGeneral?
        accesorioActual;
        if (accesorioActualPath !=
            null) {
          try {
            accesorioActual =
                _availableAccesorios
                    .firstWhere(
                      (a) =>
                          a.imagenPath ==
                          accesorioActualPath,
                    );
          } catch (e) {
            accesorioActual = null;
          }
        }

        _currentEstado = _currentEstado
            .copyWith(
              skinActual: skinActual,
              expresionActual:
                  expresionPath,
              accesorioActual:
                  accesorioActual,
              backgroundActual:
                  backgroundPath ??
                  _currentEstado
                      .backgroundActual,
              nombre:
                  nombre ??
                  _currentEstado.nombre,
              felicidad:
                  felicidad ??
                  _currentEstado
                      .felicidad,
              energia:
                  energia ??
                  _currentEstado
                      .energia,
              monedas:
                  monedas ??
                  _currentEstado
                      .monedas,
              accesoriosDesbloqueados:
                  desbloqueadosGuardados ??
                  _currentEstado
                      .accesoriosDesbloqueados,
            );

        print(
          'Configuración del avatar cargada desde Firestore.',
        );
        notifyListeners();
      } else {
        print(
          'Info: No se encontró configuración de avatar guardada para el usuario.',
        );
      }
    } catch (e) {
      print(
        'Error al cargar la configuración del avatar: $e',
      );
    }
  }

  // Getters públicos
  bool get showEditPanel =>
      _showEditPanel;
  AvatarEstado get currentEstado =>
      _currentEstado;

  // Getters para datos del Repository
  List<SkinInfo> get availableSkins =>
      _availableSkins;
  List<AccesorioGeneral>
  get availableAccesorios =>
      _availableAccesorios;
  List<String>
  get availableBackgrounds =>
      _availableBackgrounds;

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
  void updateSkin(SkinInfo newSkin) {
    _currentEstado = _currentEstado
        .copyWith(
          skinActual: newSkin,
          resetExpresion:
              true, // Limpiar expresión al cambiar skin
        );
    notifyListeners();
    saveAvatarConfigToFirestore();
  }

  /* 
  Actualiza la expresión del avatar
  Si se pasa null, limpia la expresión actual
  */
  void updateExpresion(
    String? expresion,
  ) {
    if (expresion == null) {
      _currentEstado = _currentEstado
          .copyWith(
            resetExpresion: true,
          );
    } else {
      _currentEstado = _currentEstado
          .copyWith(
            expresionActual: expresion,
          );
    }
    notifyListeners();
    saveAvatarConfigToFirestore();
  }

  /* 
  Actualiza el accesorio del avatar
  Si se pasa null, quita el accesorio actual
  */
  void updateAccesorio(
    AccesorioGeneral? accesorio,
  ) {
    if (accesorio == null) {
      _currentEstado = _currentEstado
          .copyWith(
            resetAccesorio: true,
          );
    } else {
      _currentEstado = _currentEstado
          .copyWith(
            accesorioActual: accesorio,
          );
    }
    notifyListeners();
    saveAvatarConfigToFirestore();
  }

  /* 
  Actualiza el background del avatar
  */
  void updateBackground(
    String background,
  ) {
    _currentEstado = _currentEstado
        .copyWith(
          backgroundActual: background,
        );
    notifyListeners();
    saveAvatarConfigToFirestore();
  }

  /* 
  Actualiza el nombre del avatar
  */
  void updateNombre(
    String nuevoNombre,
  ) {
    _currentEstado = _currentEstado
        .copyWith(nombre: nuevoNombre);
    notifyListeners();
    saveAvatarConfigToFirestore();
  }

  /* 
  Actualiza la felicidad del avatar (0-100)
  */
  void updateFelicidad(
    int nuevaFelicidad,
  ) {
    if (nuevaFelicidad < 0 ||
        nuevaFelicidad > 100) {
      throw ArgumentError(
        'La felicidad debe estar entre 0 y 100',
      );
    }
    _currentEstado = _currentEstado
        .copyWith(
          felicidad: nuevaFelicidad,
        );
    notifyListeners();
    saveAvatarConfigToFirestore();
  }

  /* 
  Actualiza la energía del avatar (0-100)
  */
  void updateEnergia(int nuevaEnergia) {
    if (nuevaEnergia < 0 ||
        nuevaEnergia > 100) {
      throw ArgumentError(
        'La energía debe estar entre 0 y 100',
      );
    }
    _currentEstado = _currentEstado
        .copyWith(
          energia: nuevaEnergia,
        );
    notifyListeners();
    saveAvatarConfigToFirestore();
  }

  /* 
  Verifica si un accesorio está desbloqueado
  */
  bool isAccesorioDesbloqueado(
    String nombreAccesorio,
  ) {
    return _currentEstado
        .accesoriosDesbloqueados
        .contains(nombreAccesorio);
  }

  /* 
  Intenta desbloquear un accesorio con monedas
  Retorna true si se desbloqueó exitosamente, false si no hay suficientes monedas
  */
  bool desbloquearAccesorio(
    AccesorioGeneral accesorio,
  ) {
    // Verificar si ya está desbloqueado
    if (isAccesorioDesbloqueado(
      accesorio.nombre,
    )) {
      return true; // Ya está desbloqueado
    }

    // Verificar si tiene suficientes monedas
    if (_currentEstado.monedas <
        accesorio.costoMonedas) {
      return false; // No hay suficientes monedas
    }

    // Desbloquear el accesorio
    final nuevasMonedas =
        _currentEstado.monedas -
        accesorio.costoMonedas;
    final nuevosDesbloqueados =
        Set<String>.from(
          _currentEstado
              .accesoriosDesbloqueados,
        )..add(accesorio.nombre);

    _currentEstado = _currentEstado
        .copyWith(
          monedas: nuevasMonedas,
          accesoriosDesbloqueados:
              nuevosDesbloqueados,
        );
    notifyListeners();
    saveAvatarConfigToFirestore();
    return true;
  }

  /* 
  Agrega monedas al usuario (por completar actividades, etc.)
  */
  void agregarMonedas(int cantidad) {
    _currentEstado = _currentEstado
        .copyWith(
          monedas:
              _currentEstado.monedas +
              cantidad,
        );
    notifyListeners();
    saveAvatarConfigToFirestore();
  }

  /* 
  Resetea el avatar a un estado específico
  Útil para reiniciar la personalización
  */
  void resetEstado(
    AvatarEstado nuevoEstado,
  ) {
    _currentEstado = nuevoEstado;
    _showEditPanel = false;
    notifyListeners();
    saveAvatarConfigToFirestore();
  }
}
