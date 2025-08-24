import 'package:hive/hive.dart';

part 'usuario.g.dart'; // Generado automáticamente

@HiveType(typeId: 0)
class Usuario extends HiveObject {
  @HiveField(5)
  String nombre;

  @HiveField(6)
  int edad;

  @HiveField(2)
  String ciudad;

  @HiveField(3)
  String escuela;

  @HiveField(4)
  String grado;

  @HiveField(0)
  String correo;

  @HiveField(1)
  String contrasena;

  Usuario({
    required this.nombre,
    required this.edad,
    required this.ciudad,
    required this.escuela,
    required this.grado,
    required this.correo,
    required this.contrasena,
  });
}
