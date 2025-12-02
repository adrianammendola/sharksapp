import 'package:hive/hive.dart';

part 'estadistica_partido.g.dart';

@HiveType(typeId: 2)
class EstadisticaPartido {
  // Estadísticas por set
  @HiveField(0)
  List<EstadisticaSet> estadisticasPorSet;

  // Estadísticas totales del partido
  @HiveField(1)
  EstadisticaSet estadisticasTotales;

  EstadisticaPartido({
    required this.estadisticasPorSet,
    required this.estadisticasTotales,
  });

  // Constructor para compatibilidad con versiones anteriores
  EstadisticaPartido.fromLegacy({
    double? primerServicioPorcentaje,
    double? puntosGanadosPrimerServicioPorcentaje,
    double? segundoServicioPorcentaje,
    double? puntosGanadosSegundoServicioPorcentaje,
    int? puntosGanadosSegundoServicioCantidad,
    int? doblesFaltas,
    int? golpesGanadoresDrive,
    int? golpesGanadoresReves,
    int? erroresNoForzados,
    int? erroresForzados,
  }) : estadisticasPorSet = [],
       estadisticasTotales = EstadisticaSet(
         primerServicio: 0,
         segundoServicio: 0,
         aces: 0,
         doblesFaltas: doblesFaltas ?? 0,
         winnersDrive: golpesGanadoresDrive ?? 0,
         winnersReves: golpesGanadoresReves ?? 0,
         erroresNoForzados: erroresNoForzados ?? 0,
         erroresForzados: erroresForzados ?? 0,
       );
}

@HiveType(typeId: 3)
class EstadisticaSet {
  // Servicio
  @HiveField(0)
  int primerServicio;

  @HiveField(1)
  int segundoServicio;

  @HiveField(2)
  int aces;

  @HiveField(3)
  int doblesFaltas;

  // Golpes
  @HiveField(4)
  int winnersDrive;

  @HiveField(5)
  int winnersReves;

  // Errores
  @HiveField(6)
  int erroresNoForzados;

  @HiveField(7)
  int erroresForzados;

  EstadisticaSet({
    required this.primerServicio,
    required this.segundoServicio,
    required this.aces,
    required this.doblesFaltas,
    required this.winnersDrive,
    required this.winnersReves,
    required this.erroresNoForzados,
    required this.erroresForzados,
  });

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
    );
  }
}
