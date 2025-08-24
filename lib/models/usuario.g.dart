// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usuario.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UsuarioAdapter extends TypeAdapter<Usuario> {
  @override
  final int typeId = 0;

  @override
  Usuario read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Usuario(
      nombre: fields[0] as String,
      edad: fields[1] as int,
      ciudad: fields[2] as String,
      escuela: fields[3] as String,
      grado: fields[4] as String,
      correo: fields[5] as String,
      contrasena: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Usuario obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.nombre)
      ..writeByte(1)
      ..write(obj.edad)
      ..writeByte(2)
      ..write(obj.ciudad)
      ..writeByte(3)
      ..write(obj.escuela)
      ..writeByte(4)
      ..write(obj.grado)
      ..writeByte(5)
      ..write(obj.correo)
      ..writeByte(6)
      ..write(obj.contrasena);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsuarioAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
