import 'package:flutter/material.dart';

/*
Modelo que representa la información de un módulo de aprendizaje.
Contiene los datos de título, progreso, nivel, imagen y estado de bloqueo.
*/
class ModuloInfo {
  final String id;
  final String titulo;
  final int estrellas;
  final int nivel;
  final String imagenPath;
  final Color color;
  final bool bloqueado;

  ModuloInfo({
    required this.id,
    required this.titulo,
    required this.estrellas,
    required this.nivel,
    required this.imagenPath,
    required this.color,
    this.bloqueado = false,
  });
}
