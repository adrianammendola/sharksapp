// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partido_dobles.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PartidoDoblesAdapter extends TypeAdapter<PartidoDobles> {
  @override
  final int typeId = 2;

  @override
  PartidoDobles read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PartidoDobles(
      equipo1: (fields[0] as List).cast<String>(),
      equipo2: (fields[1] as List).cast<String>(),
      setsEquipo1: (fields[2] as List).cast<int>(),
      setsEquipo2: (fields[3] as List).cast<int>(),
      fecha: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PartidoDobles obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.equipo1)
      ..writeByte(1)
      ..write(obj.equipo2)
      ..writeByte(2)
      ..write(obj.setsEquipo1)
      ..writeByte(3)
      ..write(obj.setsEquipo2)
      ..writeByte(4)
      ..write(obj.fecha);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartidoDoblesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
