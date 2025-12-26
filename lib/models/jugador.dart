import 'package:hive/hive.dart';
import 'partido.dart';

part 'jugador.g.dart';

@HiveType(typeId: 1)
class Jugador extends HiveObject {
  @HiveField(0)
  String nombre;

  @HiveField(1)
  int partidosGanados;

  @HiveField(2)
  int partidosPerdidos;

  @HiveField(3)
  List<Partido> partidos;

  @HiveField(4)
  List<dynamic> estadisticas;

  Jugador({
    required this.nombre,
    this.partidosGanados = 0,
    this.partidosPerdidos = 0,
    List<Partido>? partidos,
    List<dynamic>? estadisticas,
  })  : partidos = partidos ?? [],
        estadisticas = estadisticas ?? [];

  // Métodos para Firebase
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'partidosGanados': partidosGanados,
      'partidosPerdidos': partidosPerdidos,
      'estadisticas': estadisticas,
    };
  }

  factory Jugador.fromJson(Map<String, dynamic> json) {
    return Jugador(
      nombre: json['nombre'] ?? '',
      partidosGanados: json['partidosGanados'] ?? 0,
      partidosPerdidos: json['partidosPerdidos'] ?? 0,
      estadisticas: json['estadisticas'] as List<dynamic>?,
    );
  }
}
