import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/jugador.dart';
import '../models/partido.dart';
import '../models/estadistica_partido.dart';
import '../services/data_service.dart';
import '../services/firebase_service.dart';

class RegistrarPartidoScreen extends StatefulWidget {
  const RegistrarPartidoScreen({Key? key}) : super(key: key);

  @override
  State<RegistrarPartidoScreen> createState() => _RegistrarPartidoScreenState();
}

class _RegistrarPartidoScreenState extends State<RegistrarPartidoScreen> {
  final Box<Jugador> jugadoresBox = Hive.box<Jugador>('jugadores');
  final Box<Partido> partidosBox = Hive.box<Partido>('partidos');
  final ScrollController _scrollController = ScrollController();

  // Fecha del partido
  DateTime _fecha = DateTime.now();

  // Modo: singles o dobles
  bool esDobles = false;

  // Selección de jugadores
  String? sJugador1;
  String? sJugador2;

  // Para dobles: dos equipos de 2
  String? dEq1Jug1;
  String? dEq1Jug2;
  String? dEq2Jug1;
  String? dEq2Jug2;

  // Configuración de sets
  int numeroSets = 3; // Por defecto 3 sets
  List<Map<String, dynamic>> sets =
      []; // Lista de sets con puntuación y configuración

  // Estadísticas por jugador y por set
  final Map<String, List<Map<String, int>>> estadisticasTemp = {};

  // Set actual para estadísticas
  int setActualEstadisticas = 0;

  List<String> get _nombresJugadores =>
      jugadoresBox.values.map((j) => j.nombre).toList();

  @override
  void initState() {
    super.initState();
    _inicializarSets();
  }

  void _inicializarSets() {
    sets.clear();
    for (int i = 0; i < numeroSets; i++) {
      sets.add({
        'jugador1': 0,
        'jugador2': 0,
        'esTieBreak': false,
        'esSuperTieBreak': false,
        'puntosTieBreak1': 0,
        'puntosTieBreak2': 0,
      });
    }
  }

  // Agregar jugador manualmente
  Future<void> _agregarJugadorDialog() async {
    final controller = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar jugador'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nombre'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (nombre != null && nombre.isNotEmpty) {
      final existe = jugadoresBox.values.any(
        (j) => j.nombre.toLowerCase() == nombre.toLowerCase(),
      );
      if (!existe) {
        jugadoresBox.add(Jugador(nombre: nombre));
      }
      setState(() {});
    }
  }

  void _initStatsFor(String nombre) {
    estadisticasTemp.putIfAbsent(nombre, () {
      return List.generate(
        numeroSets,
        (index) => {
          'primerServicio': 0,
          'segundoServicio': 0,
          'aces': 0,
          'doblesFaltas': 0,
          'winnersDrive': 0,
          'winnersReves': 0,
          'erroresNoForzados': 0,
          'erroresForzados': 0,
        },
      );
    });
  }

  // Calcular porcentaje de primer servicio
  double _calcularPorcentajePrimerServicio(String nombre) {
    final stats = estadisticasTemp[nombre];
    if (stats == null || setActualEstadisticas >= stats.length) return 0.0;
    final total =
        stats[setActualEstadisticas]['primerServicio']! +
        stats[setActualEstadisticas]['segundoServicio']!;
    if (total == 0) return 0.0;
    return (stats[setActualEstadisticas]['primerServicio']! / total * 100);
  }

  // Calcular porcentaje de segundo servicio
  double _calcularPorcentajeSegundoServicio(String nombre) {
    final stats = estadisticasTemp[nombre];
    if (stats == null || setActualEstadisticas >= stats.length) return 0.0;
    final total =
        stats[setActualEstadisticas]['primerServicio']! +
        stats[setActualEstadisticas]['segundoServicio']!;
    if (total == 0) return 0.0;
    return (stats[setActualEstadisticas]['segundoServicio']! / total * 100);
  }

  // Calcular porcentaje de winners drive
  double _calcularPorcentajeWinnersDrive(String nombre) {
    final stats = estadisticasTemp[nombre];
    if (stats == null || setActualEstadisticas >= stats.length) return 0.0;
    final total =
        stats[setActualEstadisticas]['winnersDrive']! +
        stats[setActualEstadisticas]['winnersReves']!;
    if (total == 0) return 0.0;
    return (stats[setActualEstadisticas]['winnersDrive']! / total * 100);
  }

  // Calcular porcentaje de winners revés
  double _calcularPorcentajeWinnersReves(String nombre) {
    final stats = estadisticasTemp[nombre];
    if (stats == null || setActualEstadisticas >= stats.length) return 0.0;
    final total =
        stats[setActualEstadisticas]['winnersDrive']! +
        stats[setActualEstadisticas]['winnersReves']!;
    if (total == 0) return 0.0;
    return (stats[setActualEstadisticas]['winnersReves']! / total * 100);
  }

  // Calcular porcentaje de errores no forzados
  double _calcularPorcentajeErroresNoForzados(String nombre) {
    final stats = estadisticasTemp[nombre];
    if (stats == null || setActualEstadisticas >= stats.length) return 0.0;
    final total =
        stats[setActualEstadisticas]['erroresNoForzados']! +
        stats[setActualEstadisticas]['erroresForzados']!;
    if (total == 0) return 0.0;
    return (stats[setActualEstadisticas]['erroresNoForzados']! / total * 100);
  }

  // Calcular porcentaje de errores forzados
  double _calcularPorcentajeErroresForzados(String nombre) {
    final stats = estadisticasTemp[nombre];
    if (stats == null || setActualEstadisticas >= stats.length) return 0.0;
    final total =
        stats[setActualEstadisticas]['erroresNoForzados']! +
        stats[setActualEstadisticas]['erroresForzados']!;
    if (total == 0) return 0.0;
    return (stats[setActualEstadisticas]['erroresForzados']! / total * 100);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date != null) {
      setState(() => _fecha = date);
    }
  }

  Future<void> _guardarPartido() async {
    // Validaciones
    if (!esDobles && (sJugador1 == null || sJugador2 == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona ambos jugadores')),
      );
      return;
    }

    if (esDobles &&
        (dEq1Jug1 == null ||
            dEq1Jug2 == null ||
            dEq2Jug1 == null ||
            dEq2Jug2 == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona todos los jugadores')),
      );
      return;
    }

    // Verificar que el partido esté completo
    int setsJugador1 = 0;
    int setsJugador2 = 0;

    for (var set in sets) {
      final puntos1 = set['jugador1'] as int;
      final puntos2 = set['jugador2'] as int;
      final esTieBreak = set['esTieBreak'] as bool;
      final esSuperTieBreak = set['esSuperTieBreak'] as bool;

      if (esSuperTieBreak) {
        final tieBreak1 = set['puntosTieBreak1'] as int;
        final tieBreak2 = set['puntosTieBreak2'] as int;
        if (tieBreak1 > tieBreak2) {
          setsJugador1++;
        } else if (tieBreak2 > tieBreak1) {
          setsJugador2++;
        }
      } else if (esTieBreak) {
        final tieBreak1 = set['puntosTieBreak1'] as int;
        final tieBreak2 = set['puntosTieBreak2'] as int;
        if (tieBreak1 > tieBreak2) {
          setsJugador1++;
        } else if (tieBreak2 > tieBreak1) {
          setsJugador2++;
        }
      } else {
        if (puntos1 > puntos2) {
          setsJugador1++;
        } else if (puntos2 > puntos1) {
          setsJugador2++;
        }
      }
    }

    if (setsJugador1 == setsJugador2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El partido debe tener un ganador')),
      );
      return;
    }

    // Crear el partido
    List<String> jugadores;
    Map<String, int> setsMap = {};

    if (!esDobles) {
      jugadores = [sJugador1!, sJugador2!];
      setsMap = {sJugador1!: setsJugador1, sJugador2!: setsJugador2};
    } else {
      jugadores = [dEq1Jug1!, dEq1Jug2!, dEq2Jug1!, dEq2Jug2!];
      setsMap = {'Equipo 1': setsJugador1, 'Equipo 2': setsJugador2};
    }

    // Convertir estadísticas al nuevo formato
    Map<String, EstadisticaPartido> estadisticasNuevas = {};

    for (String nombre in estadisticasTemp.keys) {
      final statsPorSet = estadisticasTemp[nombre]!;

      // Crear estadísticas por set
      List<EstadisticaSet> estadisticasSets = statsPorSet
          .map(
            (setStats) => EstadisticaSet(
              primerServicio: setStats['primerServicio']!,
              segundoServicio: setStats['segundoServicio']!,
              aces: setStats['aces']!,
              doblesFaltas: setStats['doblesFaltas']!,
              winnersDrive: setStats['winnersDrive']!,
              winnersReves: setStats['winnersReves']!,
              erroresNoForzados: setStats['erroresNoForzados']!,
              erroresForzados: setStats['erroresForzados']!,
            ),
          )
          .toList();

      // Calcular estadísticas totales
      EstadisticaSet estadisticasTotales = EstadisticaSet(
        primerServicio: statsPorSet.fold(
          0,
          (sum, set) => sum + set['primerServicio']!,
        ),
        segundoServicio: statsPorSet.fold(
          0,
          (sum, set) => sum + set['segundoServicio']!,
        ),
        aces: statsPorSet.fold(0, (sum, set) => sum + set['aces']!),
        doblesFaltas: statsPorSet.fold(
          0,
          (sum, set) => sum + set['doblesFaltas']!,
        ),
        winnersDrive: statsPorSet.fold(
          0,
          (sum, set) => sum + set['winnersDrive']!,
        ),
        winnersReves: statsPorSet.fold(
          0,
          (sum, set) => sum + set['winnersReves']!,
        ),
        erroresNoForzados: statsPorSet.fold(
          0,
          (sum, set) => sum + set['erroresNoForzados']!,
        ),
        erroresForzados: statsPorSet.fold(
          0,
          (sum, set) => sum + set['erroresForzados']!,
        ),
      );

      estadisticasNuevas[nombre] = EstadisticaPartido(
        estadisticasPorSet: estadisticasSets,
        estadisticasTotales: estadisticasTotales,
      );
    }

    // Obtener el UID del usuario actual
    final currentUserId = FirebaseService.currentUserId;

    final partido = Partido(
      fecha: _fecha,
      jugadores: jugadores,
      sets: setsMap,
      esDobles: esDobles,
      estadisticas: estadisticasNuevas,
      ownerId: currentUserId, // Guardar el owner del partido
    );

    // Guardar localmente y sincronizar con Firebase
    try {
      await DataService.savePartido(partido);
    } catch (e) {
      // Si falla la sincronización en la nube, al menos guardamos localmente
      partidosBox.add(partido);
    }

    // Actualizar estadísticas de jugadores
    if (!esDobles) {
      final j1 = jugadoresBox.values.firstWhere((j) => j.nombre == sJugador1);
      final j2 = jugadoresBox.values.firstWhere((j) => j.nombre == sJugador2);

      if (setsJugador1 > setsJugador2) {
        j1.partidosGanados++;
        j2.partidosPerdidos++;
      } else {
        j2.partidosGanados++;
        j1.partidosPerdidos++;
      }
      j1.save();
      j2.save();
    } else {
      final eq1 = [dEq1Jug1!, dEq1Jug2!];
      final eq2 = [dEq2Jug1!, dEq2Jug2!];
      final eq1Gana = setsJugador1 > setsJugador2;

      for (final nombre in eq1) {
        final j = jugadoresBox.values.firstWhere((x) => x.nombre == nombre);
        if (eq1Gana)
          j.partidosGanados++;
        else
          j.partidosPerdidos++;
        j.save();
      }
      for (final nombre in eq2) {
        final j = jugadoresBox.values.firstWhere((x) => x.nombre == nombre);
        if (!eq1Gana)
          j.partidosGanados++;
        else
          j.partidosPerdidos++;
        j.save();
      }
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Partido guardado')));
    Navigator.pop(context);
  }

  Widget _buildSetCounter(int index) {
    final set = sets[index];
    final jugador1Nombre = !esDobles ? (sJugador1 ?? 'Jugador 1') : 'Equipo 1';
    final jugador2Nombre = !esDobles ? (sJugador2 ?? 'Jugador 2') : 'Equipo 2';
    final esTieBreak = set['esTieBreak'] as bool;
    final esSuperTieBreak = set['esSuperTieBreak'] as bool;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Set ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                if (index == 2 && numeroSets == 3) ...[
                  Row(
                    children: [
                      Checkbox(
                        value: esSuperTieBreak,
                        onChanged: (value) {
                          setState(() {
                            set['esSuperTieBreak'] = value ?? false;
                            if (value == true) {
                              set['esTieBreak'] = false;
                            }
                          });
                        },
                      ),
                      const Text('Super Tie-Break'),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            if (esSuperTieBreak) ...[
              // Super Tie-Break (a 10 puntos)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Super Tie-Break (a 10 puntos)',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _textFieldCounter(
                            label: jugador1Nombre,
                            value: set['puntosTieBreak1'] as int,
                            onChanged: (value) =>
                                setState(() => set['puntosTieBreak1'] = value),
                            maxValue: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          ' - ',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _textFieldCounter(
                            label: jugador2Nombre,
                            value: set['puntosTieBreak2'] as int,
                            onChanged: (value) =>
                                setState(() => set['puntosTieBreak2'] = value),
                            maxValue: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Set normal
              Row(
                children: [
                  Expanded(
                    child: _textFieldCounter(
                      label: jugador1Nombre,
                      value: set['jugador1'] as int,
                      onChanged: (value) {
                        setState(() {
                          set['jugador1'] = value;
                          // Verificar si necesita tie-break automático
                          if (value == 6 && (set['jugador2'] as int) == 6) {
                            set['esTieBreak'] = true;
                          }
                        });
                      },
                      maxValue: 7,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    ' - ',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _textFieldCounter(
                      label: jugador2Nombre,
                      value: set['jugador2'] as int,
                      onChanged: (value) {
                        setState(() {
                          set['jugador2'] = value;
                          // Verificar si necesita tie-break automático
                          if (value == 6 && (set['jugador1'] as int) == 6) {
                            set['esTieBreak'] = true;
                          }
                        });
                      },
                      maxValue: 7,
                    ),
                  ),
                ],
              ),

              // Tie-Break automático si el set está 6-6
              if ((set['jugador1'] as int) == 6 &&
                  (set['jugador2'] as int) == 6) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: esTieBreak,
                            onChanged: (value) {
                              setState(() {
                                set['esTieBreak'] = value ?? false;
                              });
                            },
                          ),
                          const Text(
                            'Tie-Break (6-6)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      if (esTieBreak) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Tie-Break (a 7 puntos)',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _textFieldCounter(
                                label: 'Tie-Break ${jugador1Nombre}',
                                value: set['puntosTieBreak1'] as int,
                                onChanged: (value) => setState(
                                  () => set['puntosTieBreak1'] = value,
                                ),
                                maxValue: 15,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              ' - ',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _textFieldCounter(
                                label: 'Tie-Break ${jugador2Nombre}',
                                value: set['puntosTieBreak2'] as int,
                                onChanged: (value) => setState(
                                  () => set['puntosTieBreak2'] = value,
                                ),
                                maxValue: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _textFieldCounter({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    int maxValue = 7,
  }) {
    final controller = TextEditingController(text: value.toString());

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
            onChanged: (text) {
              final newValue = int.tryParse(text) ?? 0;
              if (newValue >= 0 && newValue <= maxValue) {
                onChanged(newValue);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _statsRow({
    required String label,
    required int value,
    required VoidCallback onInc,
    required VoidCallback onDec,
    String? porcentaje,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: onDec,
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white,
                  ),
                  child: Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onInc,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  color: Colors.green,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              porcentaje ?? '',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsJugador(String nombre) {
    _initStatsFor(nombre);
    final m = estadisticasTemp[nombre]![setActualEstadisticas];

    // Calcular porcentajes
    final porcentajePrimerServicio = _calcularPorcentajePrimerServicio(nombre);
    final porcentajeSegundoServicio = _calcularPorcentajeSegundoServicio(
      nombre,
    );
    final porcentajeWinnersDrive = _calcularPorcentajeWinnersDrive(nombre);
    final porcentajeWinnersReves = _calcularPorcentajeWinnersReves(nombre);
    final porcentajeErroresNoForzados = _calcularPorcentajeErroresNoForzados(
      nombre,
    );
    final porcentajeErroresForzados = _calcularPorcentajeErroresForzados(
      nombre,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Estadísticas: $nombre',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<int>(
                value: setActualEstadisticas,
                underline: Container(),
                items: List.generate(
                  numeroSets,
                  (index) => DropdownMenuItem(
                    value: index,
                    child: Text('Set ${index + 1}'),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    setActualEstadisticas = value!;
                  });
                },
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Servicio
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'SERVICIO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _statsRow(
                  label: '1er Servicio',
                  value: m['primerServicio']!,
                  onInc: () => setState(
                    () => estadisticasTemp[nombre]![setActualEstadisticas]['primerServicio'] =
                        estadisticasTemp[nombre]![setActualEstadisticas]['primerServicio']! +
                        1,
                  ),
                  onDec: () => setState(
                    () => estadisticasTemp[nombre]![setActualEstadisticas]['primerServicio'] =
                        (estadisticasTemp[nombre]![setActualEstadisticas]['primerServicio']! -
                                1)
                            .clamp(0, 999),
                  ),
                  porcentaje: '${porcentajePrimerServicio.toStringAsFixed(1)}%',
                ),

                _statsRow(
                  label: '2do Servicio',
                  value: m['segundoServicio']!,
                  onInc: () => setState(
                    () => estadisticasTemp[nombre]![setActualEstadisticas]['segundoServicio'] =
                        estadisticasTemp[nombre]![setActualEstadisticas]['segundoServicio']! +
                        1,
                  ),
                  onDec: () => setState(
                    () => estadisticasTemp[nombre]![setActualEstadisticas]['segundoServicio'] =
                        (estadisticasTemp[nombre]![setActualEstadisticas]['segundoServicio']! -
                                1)
                            .clamp(0, 999),
                  ),
                  porcentaje:
                      '${porcentajeSegundoServicio.toStringAsFixed(1)}%',
                ),

                _statsRow(
                  label: 'Aces',
                  value: m['aces']!,
                  onInc: () => setState(
                    () => estadisticasTemp[nombre]![setActualEstadisticas]['aces'] =
                        estadisticasTemp[nombre]![setActualEstadisticas]['aces']! +
                        1,
                  ),
                  onDec: () => setState(
                    () => estadisticasTemp[nombre]![setActualEstadisticas]['aces'] =
                        (estadisticasTemp[nombre]![setActualEstadisticas]['aces']! -
                                1)
                            .clamp(0, 999),
                  ),
                ),

                _statsRow(
                  label: 'Dobles Faltas',
                  value: m['doblesFaltas']!,
                  onInc: () => setState(
                    () => estadisticasTemp[nombre]![setActualEstadisticas]['doblesFaltas'] =
                        estadisticasTemp[nombre]![setActualEstadisticas]['doblesFaltas']! +
                        1,
                  ),
                  onDec: () => setState(
                    () => estadisticasTemp[nombre]![setActualEstadisticas]['doblesFaltas'] =
                        (estadisticasTemp[nombre]![setActualEstadisticas]['doblesFaltas']! -
                                1)
                            .clamp(0, 999),
                  ),
                ),

                const SizedBox(height: 16),

                // Golpes
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'GOLPES',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _statsRow(
                  label: 'Winners Drive',
                  value: m['winnersDrive']!,
                  onInc: () => setState(
                    () => estadisticasTemp[nombre]![setActualEstadisticas]['winnersDrive'] =
                        estadisticasTemp[nombre]![setActualEstadisticas]['winnersDrive']! +
                        1,
                  ),
                  onDec: () => setState(
                    () => estadisticasTemp[nombre]![setActualEstadisticas]['winnersDrive'] =
                        (estadisticasTemp[nombre]![setActualEstadisticas]['winnersDrive']! -
                                1)
                            .clamp(0, 999),
                  ),
                  porcentaje: '${porcentajeWinnersDrive.toStringAsFixed(1)}%',
                ),

                _statsRow(
                  label: 'Winners Revés',
                  value: m['winnersReves']!,
                  onInc: () => setState(
                    () => estadisticasTemp[nombre]![setActualEstadisticas]['winnersReves'] =
                        estadisticasTemp[nombre]![setActualEstadisticas]['winnersReves']! +
                        1,
                  ),
                  onDec: () => setState(
                    () => estadisticasTemp[nombre]![setActualEstadisticas]['winnersReves'] =
                        (estadisticasTemp[nombre]![setActualEstadisticas]['winnersReves']! -
                                1)
                            .clamp(0, 999),
                  ),
                  porcentaje: '${porcentajeWinnersReves.toStringAsFixed(1)}%',
                ),

                const SizedBox(height: 16),

                // Errores
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ERRORES',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _statsRow(
                  label: 'Errores No Forzados',
                  value: m['erroresNoForzados']!,
                  onInc: () => setState(
                    () => estadisticasTemp[nombre]![setActualEstadisticas]['erroresNoForzados'] =
                        estadisticasTemp[nombre]![setActualEstadisticas]['erroresNoForzados']! +
                        1,
                  ),
                  onDec: () => setState(
                    () => estadisticasTemp[nombre]![setActualEstadisticas]['erroresNoForzados'] =
                        (estadisticasTemp[nombre]![setActualEstadisticas]['erroresNoForzados']! -
                                1)
                            .clamp(0, 999),
                  ),
                  porcentaje:
                      '${porcentajeErroresNoForzados.toStringAsFixed(1)}%',
                ),

                _statsRow(
                  label: 'Errores Forzados',
                  value: m['erroresForzados']!,
                  onInc: () => setState(
                    () => estadisticasTemp[nombre]![setActualEstadisticas]['erroresForzados'] =
                        estadisticasTemp[nombre]![setActualEstadisticas]['erroresForzados']! +
                        1,
                  ),
                  onDec: () => setState(
                    () => estadisticasTemp[nombre]![setActualEstadisticas]['erroresForzados'] =
                        (estadisticasTemp[nombre]![setActualEstadisticas]['erroresForzados']! -
                                1)
                            .clamp(0, 999),
                  ),
                  porcentaje:
                      '${porcentajeErroresForzados.toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombres = _nombresJugadores;

    Widget _dropdownJugador({
      required String label,
      required String? value,
      required ValueChanged<String?> onChanged,
    }) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: value,
                  hint: Text(label),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: nombres
                      .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                      .toList(),
                  onChanged: (val) => setState(() => onChanged(val)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Agregar jugador',
                onPressed: _agregarJugadorDialog,
                icon: const Icon(Icons.person_add),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Partido'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Elegir fecha',
            onPressed: _pickDate,
            icon: const Icon(Icons.event),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final bool wide = width >= 920;
          final double maxWidth = wide ? 1100 : double.infinity;
          final EdgeInsets pagePadding = const EdgeInsets.all(16);

          Widget content = Column(
            children: [
              // Selector Singles / Dobles
              Card(
                child: SwitchListTile(
                  title: const Text('¿Dobles?'),
                  value: esDobles,
                  onChanged: (v) => setState(() {
                    esDobles = v;
                    sJugador1 = sJugador2 = null;
                    dEq1Jug1 = dEq1Jug2 = dEq2Jug1 = dEq2Jug2 = null;
                    estadisticasTemp.clear();
                    _inicializarSets();
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Fecha: ${_fecha.toLocal().toString().split(' ').first}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Selector de número de sets
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Número de sets:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [3, 5]
                            .map(
                              (num) => Expanded(
                                child: RadioListTile<int>(
                                  title: Text('$num sets'),
                                  value: num,
                                  groupValue: numeroSets,
                                  onChanged: (value) {
                                    setState(() {
                                      numeroSets = value!;
                                      _inicializarSets();
                                    });
                                  },
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (!esDobles) ...[
                if (wide)
                  Row(
                    children: [
                      Expanded(
                        child: _dropdownJugador(
                          label: 'Jugador 1',
                          value: sJugador1,
                          onChanged: (v) => sJugador1 = v,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dropdownJugador(
                          label: 'Jugador 2',
                          value: sJugador2,
                          onChanged: (v) => sJugador2 = v,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _dropdownJugador(
                    label: 'Jugador 1',
                    value: sJugador1,
                    onChanged: (v) => sJugador1 = v,
                  ),
                  _dropdownJugador(
                    label: 'Jugador 2',
                    value: sJugador2,
                    onChanged: (v) => sJugador2 = v,
                  ),
                ],
              ] else ...[
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Equipo 1',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _dropdownJugador(
                                  label: 'Jugador 1 - Equipo 1',
                                  value: dEq1Jug1,
                                  onChanged: (v) => dEq1Jug1 = v,
                                ),
                                _dropdownJugador(
                                  label: 'Jugador 2 - Equipo 1',
                                  value: dEq1Jug2,
                                  onChanged: (v) => dEq1Jug2 = v,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Equipo 2',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _dropdownJugador(
                                  label: 'Jugador 1 - Equipo 2',
                                  value: dEq2Jug1,
                                  onChanged: (v) => dEq2Jug1 = v,
                                ),
                                _dropdownJugador(
                                  label: 'Jugador 2 - Equipo 2',
                                  value: dEq2Jug2,
                                  onChanged: (v) => dEq2Jug2 = v,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Equipo 1',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _dropdownJugador(
                            label: 'Jugador 1 - Equipo 1',
                            value: dEq1Jug1,
                            onChanged: (v) => dEq1Jug1 = v,
                          ),
                          _dropdownJugador(
                            label: 'Jugador 2 - Equipo 1',
                            value: dEq1Jug2,
                            onChanged: (v) => dEq1Jug2 = v,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Equipo 2',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _dropdownJugador(
                            label: 'Jugador 1 - Equipo 2',
                            value: dEq2Jug1,
                            onChanged: (v) => dEq2Jug1 = v,
                          ),
                          _dropdownJugador(
                            label: 'Jugador 2 - Equipo 2',
                            value: dEq2Jug2,
                            onChanged: (v) => dEq2Jug2 = v,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Puntuación por Set:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(height: 12),

              // Contadores de sets
              ...List.generate(numeroSets, (index) => _buildSetCounter(index)),

              const SizedBox(height: 16),

              // Estadísticas por jugador (opcional)
              if (!esDobles) ...[
                if (sJugador1 != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _statsJugador(sJugador1!),
                  ),
                if (sJugador2 != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _statsJugador(sJugador2!),
                  ),
              ] else ...[
                if (dEq1Jug1 != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _statsJugador(dEq1Jug1!),
                  ),
                if (dEq1Jug2 != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _statsJugador(dEq1Jug2!),
                  ),
                if (dEq2Jug1 != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _statsJugador(dEq2Jug1!),
                  ),
                if (dEq2Jug2 != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _statsJugador(dEq2Jug2!),
                  ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _guardarPartido,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar partido'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          );

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: wide,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: pagePadding,
                  child: content,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
