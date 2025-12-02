import 'package:hive/hive.dart';
import 'estadistica_partido.dart';

part 'partido.g.dart';

@HiveType(typeId: 0)
class Partido extends HiveObject {
  @HiveField(0)
  final DateTime fecha;

  @HiveField(1)
  final List<String> jugadores;

  @HiveField(2)
  final Map<String, int> sets;

  @HiveField(3)
  final bool esDobles;

  @HiveField(4)
  final Map<String, EstadisticaPartido> estadisticas;

  @HiveField(5) // New field
  final List<String> sharedWith;

  @HiveField(6) // Owner ID
  final String? ownerId;

  Partido({
    required this.fecha,
    required this.jugadores,
    required this.sets,
    required this.esDobles,
    required this.estadisticas,
    this.sharedWith = const [], // Initialize with an empty list
    this.ownerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'fecha': fecha.toIso8601String(),
      'jugadores': jugadores,
      'sets': sets,
      'esDobles': esDobles,
      'estadisticas': estadisticas.map(
        (key, value) => MapEntry(key, {
          'estadisticasPorSet': value.estadisticasPorSet
              .map(
                (set) => {
                  'primerServicio': set.primerServicio,
                  'segundoServicio': set.segundoServicio,
                  'aces': set.aces,
                  'doblesFaltas': set.doblesFaltas,
                  'winnersDrive': set.winnersDrive,
                  'winnersReves': set.winnersReves,
                  'erroresNoForzados': set.erroresNoForzados,
                  'erroresForzados': set.erroresForzados,
                },
              )
              .toList(),
          'estadisticasTotales': {
            'primerServicio': value.estadisticasTotales.primerServicio,
            'segundoServicio': value.estadisticasTotales.segundoServicio,
            'aces': value.estadisticasTotales.aces,
            'doblesFaltas': value.estadisticasTotales.doblesFaltas,
            'winnersDrive': value.estadisticasTotales.winnersDrive,
            'winnersReves': value.estadisticasTotales.winnersReves,
            'erroresNoForzados': value.estadisticasTotales.erroresNoForzados,
            'erroresForzados': value.estadisticasTotales.erroresForzados,
          },
        }),
      ),
      'sharedWith': sharedWith, // Add to toJson
      'ownerId': ownerId, // Add ownerId to JSON
    };
  }

  factory Partido.fromJson(Map<String, dynamic> json) {
    Map<String, EstadisticaPartido> estadisticasNuevas = {};

    if (json['estadisticas'] != null) {
      final statsJson = json['estadisticas'] as Map<String, dynamic>;
      for (String key in statsJson.keys) {
        final value = statsJson[key] as Map<String, dynamic>;

        // Convertir estadísticas por set
        List<EstadisticaSet> estadisticasPorSet = [];
        if (value['estadisticasPorSet'] != null) {
          final setsJson = value['estadisticasPorSet'] as List<dynamic>;
          estadisticasPorSet = setsJson
              .map(
                (setJson) => EstadisticaSet(
                  primerServicio: setJson['primerServicio'] ?? 0,
                  segundoServicio: setJson['segundoServicio'] ?? 0,
                  aces: setJson['aces'] ?? 0,
                  doblesFaltas: setJson['doblesFaltas'] ?? 0,
                  winnersDrive: setJson['winnersDrive'] ?? 0,
                  winnersReves: setJson['winnersReves'] ?? 0,
                  erroresNoForzados: setJson['erroresNoForzados'] ?? 0,
                  erroresForzados: setJson['erroresForzados'] ?? 0,
                ),
              )
              .toList();
        }

        // Convertir estadísticas totales
        EstadisticaSet estadisticasTotales = EstadisticaSet(
          primerServicio: value['estadisticasTotales']?['primerServicio'] ?? 0,
          segundoServicio:
              value['estadisticasTotales']?['segundoServicio'] ?? 0,
          aces: value['estadisticasTotales']?['aces'] ?? 0,
          doblesFaltas: value['estadisticasTotales']?['doblesFaltas'] ?? 0,
          winnersDrive: value['estadisticasTotales']?['winnersDrive'] ?? 0,
          winnersReves: value['estadisticasTotales']?['winnersReves'] ?? 0,
          erroresNoForzados:
              value['estadisticasTotales']?['erroresNoForzados'] ?? 0,
          erroresForzados:
              value['estadisticasTotales']?['erroresForzados'] ?? 0,
        );

        estadisticasNuevas[key] = EstadisticaPartido(
          estadisticasPorSet: estadisticasPorSet,
          estadisticasTotales: estadisticasTotales,
        );
      }
    }

    return Partido(
      fecha: DateTime.parse(json['fecha']),
      jugadores: List<String>.from(json['jugadores']),
      sets: Map<String, int>.from(json['sets']),
      esDobles: json['esDobles'],
      estadisticas: estadisticasNuevas,
      sharedWith: List<String>.from(json['sharedWith'] ?? []), // Add to fromJson
      ownerId: json['ownerId'], // Add ownerId from JSON
    );
  }
}
