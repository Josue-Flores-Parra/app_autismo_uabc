import 'package:flutter/foundation.dart';
import '../model/avatar_models.dart';
import '../data/avatar_repository.dart';

/*
VIEWMODEL DEL AVATAR
Maneja el estado y la lógica de presentación del avatar
Usa ChangeNotifier para notificar cambios a la UI
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
  }
}
