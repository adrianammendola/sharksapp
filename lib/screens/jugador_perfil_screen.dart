import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/jugador.dart';
import '../models/partido.dart';

class JugadorPerfilScreen extends StatelessWidget {
  final Jugador jugador;

  const JugadorPerfilScreen({Key? key, required this.jugador})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Box<Partido> partidosBox = Hive.box<Partido>('partidos');

    // Filtrar partidos donde participó el jugador
    final partidosJugador = partidosBox.values
        .where((p) => p.jugadores.contains(jugador.nombre))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(jugador.nombre)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final double maxWidth = width >= 920 ? 900 : double.infinity;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              jugador.nombre,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Partidos jugados: ${partidosJugador.length}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              'Partidos ganados: ${jugador.partidosGanados}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'Partidos perdidos: ${jugador.partidosPerdidos}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Historial de Partidos',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...partidosJugador.map((p) {
                      // Rival directo
                      final rival = p.jugadores.firstWhere(
                        (j) => j != jugador.nombre,
                      );

                      // Sets tal cual fueron guardados (sin sumatorias globales)
                      final setsJugador = p.sets[jugador.nombre] ?? 0;
                      final setsRival = p.sets[rival] ?? 0;

                      // Resultado del partido
                      final ganador = setsJugador > setsRival;

                      // Estadísticas cargadas en el partido para este jugador
                      final stats =
                          p.estadisticas[jugador.nombre]?.estadisticasTotales;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Vs $rival',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Sets: $setsJugador - $setsRival',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: ganador ? Colors.green : Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  ganador ? 'GANÓ' : 'PERDIÓ',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'Fecha: ${p.fecha.toLocal().toString().split(' ').first}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          children: [
                            if (stats != null) ...[
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Servicio
                                    const Text(
                                      'SERVICIO',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _statsRow(
                                      '1er Servicio',
                                      stats.primerServicio,
                                      stats.porcentajePrimerServicio,
                                    ),
                                    _statsRow(
                                      '2do Servicio',
                                      stats.segundoServicio,
                                      stats.porcentajeSegundoServicio,
                                    ),
                                    _statsRow('Aces', stats.aces),
                                    _statsRow(
                                      'Dobles Faltas',
                                      stats.doblesFaltas,
                                    ),

                                    const SizedBox(height: 12),

                                    // Golpes
                                    const Text(
                                      'GOLPES',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.green,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _statsRow(
                                      'Winners Drive',
                                      stats.winnersDrive,
                                      stats.porcentajeWinnersDrive,
                                    ),
                                    _statsRow(
                                      'Winners Revés',
                                      stats.winnersReves,
                                      stats.porcentajeWinnersReves,
                                    ),

                                    const SizedBox(height: 12),

                                    // Errores
                                    const Text(
                                      'ERRORES',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.red,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _statsRow(
                                      'Errores No Forzados',
                                      stats.erroresNoForzados,
                                      stats.porcentajeErroresNoForzados,
                                    ),
                                    _statsRow(
                                      'Errores Forzados',
                                      stats.erroresForzados,
                                      stats.porcentajeErroresForzados,
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'No hay estadísticas disponibles para este partido',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statsRow(String label, int value, [double? porcentaje]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value.toString(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              porcentaje != null ? '${porcentaje.toStringAsFixed(1)}%' : '-',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: porcentaje != null ? Colors.blue : Colors.grey,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
