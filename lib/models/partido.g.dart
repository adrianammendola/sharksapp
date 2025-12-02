// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partido.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PartidoAdapter extends TypeAdapter<Partido> {
  @override
  final int typeId = 0;

  @override
  Partido read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Partido(
      fecha: fields[0] as DateTime,
      jugadores: (fields[1] as List).cast<String>(),
      sets: (fields[2] as Map).cast<String, int>(),
      esDobles: fields[3] as bool,
      estadisticas: (fields[4] as Map).cast<String, EstadisticaPartido>(),
      sharedWith: (fields[5] as List).cast<String>(),
      ownerId: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Partido obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.fecha)
      ..writeByte(1)
      ..write(obj.jugadores)
      ..writeByte(2)
      ..write(obj.sets)
      ..writeByte(3)
      ..write(obj.esDobles)
      ..writeByte(4)
      ..write(obj.estadisticas)
      ..writeByte(5)
      ..write(obj.sharedWith)
      ..writeByte(6)
      ..write(obj.ownerId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartidoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
