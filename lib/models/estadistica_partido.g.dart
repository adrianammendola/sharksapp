// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'estadistica_partido.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EstadisticaPartidoAdapter extends TypeAdapter<EstadisticaPartido> {
  @override
  final int typeId = 2;

  @override
  EstadisticaPartido read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EstadisticaPartido(
      estadisticasPorSet: (fields[0] as List).cast<EstadisticaSet>(),
      estadisticasTotales: fields[1] as EstadisticaSet,
    );
  }

  @override
  void write(BinaryWriter writer, EstadisticaPartido obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.estadisticasPorSet)
      ..writeByte(1)
      ..write(obj.estadisticasTotales);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstadisticaPartidoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EstadisticaSetAdapter extends TypeAdapter<EstadisticaSet> {
  @override
  final int typeId = 3;

  @override
  EstadisticaSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EstadisticaSet(
      primerServicio: fields[0] as int,
      segundoServicio: fields[1] as int,
      aces: fields[2] as int,
      doblesFaltas: fields[3] as int,
      winnersDrive: fields[4] as int,
      winnersReves: fields[5] as int,
      erroresNoForzados: fields[6] as int,
      erroresForzados: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, EstadisticaSet obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.primerServicio)
      ..writeByte(1)
      ..write(obj.segundoServicio)
      ..writeByte(2)
      ..write(obj.aces)
      ..writeByte(3)
      ..write(obj.doblesFaltas)
      ..writeByte(4)
      ..write(obj.winnersDrive)
      ..writeByte(5)
      ..write(obj.winnersReves)
      ..writeByte(6)
      ..write(obj.erroresNoForzados)
      ..writeByte(7)
      ..write(obj.erroresForzados);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstadisticaSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
