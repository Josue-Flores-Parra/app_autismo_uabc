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
  final String? descripcion;

  ModuloInfo({
    required this.id,
    required this.titulo,
    required this.estrellas,
    required this.nivel,
    required this.imagenPath,
    required this.color,
    this.bloqueado = false,
    this.descripcion,
  });

  /*
  Factory constructor para crear ModuloInfo desde datos de Firestore
  */
  factory ModuloInfo.fromFirestore(
    Map<String, dynamic> data, {
    int estrellas = 0,
  }) {
    return ModuloInfo(
      id: data['id'] ?? '',
      titulo: data['titulo'] ?? '',
      descripcion: data['descripcion'],
      estrellas: estrellas,
      nivel: data['nivelMinimo'] ?? 1,
      imagenPath: data['imagenUrl'] ?? '',
      color: _parseColor(data['color']),
      bloqueado: data['bloqueado'] ?? false,
    );
  }

  /*
  Helper para convertir string de color hexadecimal a Color
  */
  static Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return Colors.grey;
    }

    // Remove # if present
    String hexColor = colorString.replaceAll('#', '');

    // Add alpha if not present (FF for full opacity)
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }

    try {
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  /*
  Convierte ModuloInfo a Map para Firestore
  */
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'nivelMinimo': nivel,
      'imagenUrl': imagenPath,
      'color': '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
      'bloqueado': bloqueado,
    };
  }
}
