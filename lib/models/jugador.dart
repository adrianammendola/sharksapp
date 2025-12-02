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
  List<Map<String, dynamic>> estadisticas;

  Jugador({
    required this.nombre,
    this.partidosGanados = 0,
    this.partidosPerdidos = 0,
    List<Partido>? partidos,
    List<Map<String, dynamic>>? estadisticas,
  }) : partidos = partidos ?? [],
       estadisticas = estadisticas ?? [];

  void agregarEstadisticas(Map<String, int> nuevas) {
    if (estadisticas.isEmpty) {
      estadisticas.add(Map<String, dynamic>.from(nuevas));
    } else {
      nuevas.forEach((key, value) {
        estadisticas[0][key] = (estadisticas[0][key] ?? 0) + value;
      });
    }
    save();
  }

  Map<String, double> calcularPorcentajes() {
    if (estadisticas.isEmpty) return {};
    final e = estadisticas[0];
    Map<String, double> porcentajes = {};

    void calc(String buenos, String totales) {
      if ((e[totales] ?? 0) > 0) {
        porcentajes[buenos] = ((e[buenos] ?? 0) / (e[totales] ?? 1) * 100)
            .toDouble();
      } else {
        porcentajes[buenos] = 0;
      }
    }

    calc("saquesBuenos", "saquesTotales");
    calc("drivesBuenos", "drivesTotales");
    calc("revesBuenos", "revesTotales");
    calc("voleasBuenos", "voleasTotales");

    return porcentajes;
  }

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
      estadisticas: List<Map<String, dynamic>>.from(json['estadisticas'] ?? []),
    );
  }
}
