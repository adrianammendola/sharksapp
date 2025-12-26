import 'package:hive/hive.dart';

class EstadisticaPartido {
  List<EstadisticaSet> estadisticasPorSet;
  EstadisticaSet estadisticasTotales;

  EstadisticaPartido({
    required this.estadisticasPorSet,
    required this.estadisticasTotales,
  });
}

class EstadisticaSet {
  int primerServicio;
  int segundoServicio;
  int aces;
  int doblesFaltas;
  int winnersDrive;
  int winnersReves;
  int erroresNoForzados;
  int erroresForzados;
  
  // Clave: ID_stat + "_won" o "_lost", Valor: Cantidad
  Map<String, int> customStats;

  EstadisticaSet({
    this.primerServicio = 0,
    this.segundoServicio = 0,
    this.aces = 0,
    this.doblesFaltas = 0,
    this.winnersDrive = 0,
    this.winnersReves = 0,
    this.erroresNoForzados = 0,
    this.erroresForzados = 0,
    Map<String, int>? customStats,
  }) : customStats = customStats ?? {};

  // Métodos para calcular porcentajes
  double get porcentajePrimerServicio {
    final total = primerServicio + segundoServicio;
    return total > 0 ? (primerServicio / total) * 100 : 0.0;
  }

  double get porcentajeSegundoServicio {
    final total = primerServicio + segundoServicio;
    return total > 0 ? (segundoServicio / total) * 100 : 0.0;
  }

  double get porcentajeWinnersDrive {
    final total = winnersDrive + winnersReves;
    return total > 0 ? (winnersDrive / total) * 100 : 0.0;
  }

  double get porcentajeWinnersReves {
    final total = winnersDrive + winnersReves;
    return total > 0 ? (winnersReves / total) * 100 : 0.0;
  }

  double get porcentajeErroresNoForzados {
    final total = erroresNoForzados + erroresForzados;
    return total > 0 ? (erroresNoForzados / total) * 100 : 0.0;
  }

  double get porcentajeErroresForzados {
    final total = erroresNoForzados + erroresForzados;
    return total > 0 ? (erroresForzados / total) * 100 : 0.0;
  }

  // Método para crear una copia
  EstadisticaSet copyWith({
    int? primerServicio,
    int? segundoServicio,
    int? aces,
    int? doblesFaltas,
    int? winnersDrive,
    int? winnersReves,
    int? erroresNoForzados,
    int? erroresForzados,
    Map<String, int>? customStats,
  }) {
    return EstadisticaSet(
      primerServicio: primerServicio ?? this.primerServicio,
      segundoServicio: segundoServicio ?? this.segundoServicio,
      aces: aces ?? this.aces,
      doblesFaltas: doblesFaltas ?? this.doblesFaltas,
      winnersDrive: winnersDrive ?? this.winnersDrive,
      winnersReves: winnersReves ?? this.winnersReves,
      erroresNoForzados: erroresNoForzados ?? this.erroresNoForzados,
      erroresForzados: erroresForzados ?? this.erroresForzados,
      customStats: customStats ?? this.customStats,
    );
  }
}

// ========== ADAPTADORES MANUALES PARA HIVE ==========

class EstadisticaPartidoAdapter extends TypeAdapter<EstadisticaPartido> {
  @override
  final int typeId = 2;

  @override
  EstadisticaPartido read(BinaryReader reader) {
    return EstadisticaPartido(
      estadisticasPorSet: (reader.read() as List).cast<EstadisticaSet>(),
      estadisticasTotales: reader.read() as EstadisticaSet,
    );
  }

  @override
  void write(BinaryWriter writer, EstadisticaPartido obj) {
    writer.write(obj.estadisticasPorSet);
    writer.write(obj.estadisticasTotales);
  }
}

class EstadisticaSetAdapter extends TypeAdapter<EstadisticaSet> {
  @override
  final int typeId = 3;

  @override
  EstadisticaSet read(BinaryReader reader) {
    return EstadisticaSet(
      primerServicio: reader.read(),
      segundoServicio: reader.read(),
      aces: reader.read(),
      doblesFaltas: reader.read(),
      winnersDrive: reader.read(),
      winnersReves: reader.read(),
      erroresNoForzados: reader.read(),
      erroresForzados: reader.read(),
      customStats: (reader.read() as Map).cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, EstadisticaSet obj) {
    writer.write(obj.primerServicio);
    writer.write(obj.segundoServicio);
    writer.write(obj.aces);
    writer.write(obj.doblesFaltas);
    writer.write(obj.winnersDrive);
    writer.write(obj.winnersReves);
    writer.write(obj.erroresNoForzados);
    writer.write(obj.erroresForzados);
    writer.write(obj.customStats);
  }
}
