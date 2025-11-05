import 'package:flutter/material.dart';
import '../model/modulo_info.dart';

/*
ViewModel que maneja la lógica de negocio y el estado de la lista de módulos.
Extiende ChangeNotifier para poder notificar a las vistas cuando el estado cambia.
*/
class ModuleListViewModel extends ChangeNotifier {
  List<ModuloInfo> _modulos = [];
  final String _nombreUsuario = 'MrBeast';
  final int _nivelUsuario = 2;

  List<ModuloInfo> get modulos => _modulos;
  String get nombreUsuario => _nombreUsuario;
  int get nivelUsuario => _nivelUsuario;

  /*
  Constructor que inicializa el ViewModel cargando los módulos.
  */
  ModuleListViewModel() {
    _cargarModulos();
  }

  /*
  Carga la lista inicial de módulos con sus respectivos estados.
  */
  void _cargarModulos() {
    _modulos = [
      ModuloInfo(
        id: 'alimentacion_01',
        titulo: 'Alimentación',
        estrellas: 3,
        nivel: 1,
        imagenPath: 'assets/images/ALIMENTACION.jpg',
        color: Colors.orange,
      ),
      ModuloInfo(
        id: 'higiene_01',
        titulo: 'Higiene',
        estrellas: 2,
        nivel: 2,
        imagenPath: 'assets/images/HIGIENE.jpg',
        color: Colors.blue,
      ),
      ModuloInfo(
        id: 'dormir_01',
        titulo: 'Dormir',
        estrellas: 3,
        nivel: 1,
        imagenPath: 'assets/images/DORMIR.jpg',
        color: Colors.purple,
      ),
      ModuloInfo(
        id: 'socializar_01',
        titulo: 'Socializar',
        estrellas: 0,
        nivel: 3,
        imagenPath: 'assets/images/SOCIALIZAR.jpg',
        color: Colors.green,
        bloqueado: true,
      ),
    ];
    notifyListeners();
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
      );
      notifyListeners();
    }
  }
}
