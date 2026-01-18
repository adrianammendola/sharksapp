import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/estadistica_partido.dart';
import '../models/partido.dart';
import '../models/custom_stat_config.dart';
import '../services/data_service.dart';
import '../services/firebase_service.dart';
import 'share_match_screen.dart'; // Import the new screen
import 'package:intl/intl.dart';

class PartidoDetalleScreen extends StatefulWidget {
  final Partido partido;

  const PartidoDetalleScreen({super.key, required this.partido});

  @override
  State<PartidoDetalleScreen> createState() => _PartidoDetalleScreenState();
}

class _PartidoDetalleScreenState extends State<PartidoDetalleScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  int _selectedSet = 0; // 0 for total, 1 for set 1, etc.
  List<CustomStatConfig> _customStatsConfig = [];

  @override
  void initState() {
    super.initState();
    _loadCustomStatsConfig();
  }

  void _loadCustomStatsConfig() {
    // 1. Obtener configuración local
    final localConfig = DataService.getCustomStats();
    
    // 2. Crear mapa base para combinar (ID -> Config)
    final Map<String, CustomStatConfig> configMap = {
      for (var c in localConfig) c.id: c
    };

    // 3. Incorporar definiciones del partido que falten localmente
    if (widget.partido.customStatNames.isNotEmpty) {
      widget.partido.customStatNames.forEach((id, name) {
        if (!configMap.containsKey(id)) {
          configMap[id] = CustomStatConfig(id: id, name: name);
        }
      });
    }

    setState(() {
      _customStatsConfig = configMap.values.toList();
    });
  }

  // Usar el ownerId del partido, o el usuario actual como fallback
  String get _partidoOwnerId {
    return widget.partido.ownerId ?? FirebaseService.currentUserId ?? '';
  }

  String get _partidoId {
      return '${widget.partido.fecha.millisecondsSinceEpoch}_${widget.partido.jugadores.join('_')}';
  }

  String _formatDate(DateTime date) {
    try {
      // Intentar usar el formato con locale español
      return DateFormat.yMMMMd('es_ES').add_jm().format(date);
    } catch (e) {
      // Si falla (locale no inicializado), usar formato simple
      final months = [
        'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
        'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
      ];
      final month = months[date.month - 1];
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '${date.day} de $month de ${date.year}, $hour:$minute';
    }
  }

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final text = _commentController.text.trim();
    _commentController.clear();

    try {
      await FirebaseService.addComment(_partidoOwnerId, _partidoId, text);
      // El scroll se moverá al inicio de la lista de comentarios
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar el comentario: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateStat(String jugador, String statKey, int delta, {bool isCustom = false}) {
    setState(() {
      final stats = widget.partido.estadisticas[jugador]!;
      // Por simplicidad, actualizamos las estadísticas TOTALES en esta vista
      final totalStats = stats.estadisticasTotales;

      if (isCustom) {
        final currentVal = totalStats.customStats[statKey] ?? 0;
        totalStats.customStats[statKey] = (currentVal + delta).clamp(0, 999);
      } else {
        switch (statKey) {
          case 'aces':
            totalStats.aces = (totalStats.aces + delta).clamp(0, 999);
            break;
          case 'doblesFaltas':
            totalStats.doblesFaltas = (totalStats.doblesFaltas + delta).clamp(0, 999);
            break;
          case 'winnersDrive':
            totalStats.winnersDrive = (totalStats.winnersDrive + delta).clamp(0, 999);
            break;
          case 'winnersReves':
            totalStats.winnersReves = (totalStats.winnersReves + delta).clamp(0, 999);
            break;
          case 'erroresNoForzadosDrive':
            totalStats.erroresNoForzadosDrive = (totalStats.erroresNoForzadosDrive + delta).clamp(0, 999);
            break;
          // ... (se necesitarían más casos para editar todos los campos nuevos, pero por simplicidad en edición rápida mantenemos lo básico o expandimos si es necesario)
          // Para mantener la consistencia con la solicitud de "ver mejor reflejado", nos enfocamos en la visualización.
            break;
        }
      }
      
      // Guardar cambios automáticamente
      widget.partido.save(); 
      DataService.savePartido(widget.partido);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Partido'),
        actions: [
          // Mostrar botón de compartir solo si es dueño Y es profesor/admin
          Builder(
            builder: (context) {
              final isOwner = FirebaseService.currentUserId == (widget.partido.ownerId ?? FirebaseService.currentUserId);
              return FutureBuilder<String?>(
                future: FirebaseService.getUserRole(),
                builder: (context, snapshot) {
                  final userRole = snapshot.data;
                  final canShare = isOwner && (userRole == 'profesor' || userRole == 'admin');
                  
                  if (canShare) {
                    return IconButton(
                      icon: const Icon(Icons.share),
                      tooltip: 'Compartir partido',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ShareMatchScreen(partido: widget.partido),
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildMatchSummary(context),
                ),
                const Divider(height: 1),
                _buildCommentsSection(context),
              ],
            ),
          ),
          _buildCommentInputField(context),
        ],
      ),
    );
  }

  Widget _buildMatchSummary(BuildContext context) {
    // Determinar nombres de jugadores/equipos
    String p1Name, p2Name;
    if (widget.partido.esDobles) {
      p1Name = 'Equipo 1';
      p2Name = 'Equipo 2';
    } else {
      p1Name = widget.partido.jugadores.isNotEmpty ? widget.partido.jugadores[0] : 'Jugador 1';
      p2Name = widget.partido.jugadores.length > 1 ? widget.partido.jugadores[1] : 'Jugador 2';
    }

    // Obtener sets ganados (usando las claves correctas)
    final setsP1 = widget.partido.sets[p1Name] ?? widget.partido.sets[widget.partido.jugadores.isNotEmpty ? widget.partido.jugadores[0] : ''] ?? 0;
    final setsP2 = widget.partido.sets[p2Name] ?? widget.partido.sets[widget.partido.jugadores.length > 1 ? widget.partido.jugadores[1] : ''] ?? 0;

    // Calcular games totales si hay detalles
    int gamesP1 = 0;
    int gamesP2 = 0;
    bool hasDetails = widget.partido.detallesSets.isNotEmpty;

    if (hasDetails) {
      for (var set in widget.partido.detallesSets) {
        if (set['esSuperTieBreak'] == true) {
          // En super tie break, sumamos 1 game al ganador para el conteo total
          int pt1 = set['puntosTieBreak1'] ?? 0;
          int pt2 = set['puntosTieBreak2'] ?? 0;
          if (pt1 > pt2) gamesP1++;
          else if (pt2 > pt1) gamesP2++;
        } else {
          gamesP1 += (set['jugador1'] as int? ?? 0);
          gamesP2 += (set['jugador2'] as int? ?? 0);
        }
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              _formatDate(widget.partido.fecha),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Tabla de Puntuación (Scoreboard)
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3), // Nombre
                // Las columnas de sets se ajustan automáticamente
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                // Encabezados
                TableRow(
                  children: [
                    const SizedBox(), // Espacio nombre
                    ...List.generate(widget.partido.detallesSets.length, (index) => Center(child: Text('S${index + 1}', style: const TextStyle(color: Colors.grey, fontSize: 12)))),
                    const Center(child: Text('Sets', style: TextStyle(fontWeight: FontWeight.bold))),
                    if (hasDetails) const Center(child: Text('Games', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                const TableRow(children: [SizedBox(height: 8), ...[], SizedBox(), if(false) SizedBox()]), // Spacer
                
                // Fila Jugador 1
                TableRow(
                  children: [
                    Text(p1Name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ...widget.partido.detallesSets.map((set) => Center(child: _buildSetScore(set, true))),
                    Center(child: Text('$setsP1', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue))),
                    if (hasDetails) Center(child: Text('$gamesP1', style: const TextStyle(color: Colors.grey))),
                  ],
                ),
                
                // Spacer row
                const TableRow(children: [SizedBox(height: 12), ...[], SizedBox(), if(false) SizedBox()]),
                
                // Fila Jugador 2
                TableRow(
                  children: [
                    Text(p2Name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ...widget.partido.detallesSets.map((set) => Center(child: _buildSetScore(set, false))),
                    Center(child: Text('$setsP2', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue))),
                    if (hasDetails) Center(child: Text('$gamesP2', style: const TextStyle(color: Colors.grey))),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildStatsDropdown(context),
            const SizedBox(height: 16),
            _buildStatsContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSetScore(Map<String, dynamic> set, bool isPlayer1) {
    if (set['esSuperTieBreak'] == true) {
      final p1 = set['puntosTieBreak1'] ?? 0;
      final p2 = set['puntosTieBreak2'] ?? 0;
      return Text(isPlayer1 ? '$p1' : '$p2', style: const TextStyle(fontStyle: FontStyle.italic));
    }
    
    final g1 = set['jugador1'] ?? 0;
    final g2 = set['jugador2'] ?? 0;
    final score = isPlayer1 ? '$g1' : '$g2';
    
    if (set['esTieBreak'] == true) {
      final tb1 = set['puntosTieBreak1'] ?? 0;
      final tb2 = set['puntosTieBreak2'] ?? 0;
      // Mostrar puntaje de tiebreak pequeño si es relevante (ej: 7-6(4))
      if (isPlayer1 && g1 == 6 && g2 == 7) return Row(mainAxisSize: MainAxisSize.min, children: [Text(score), Text('($tb1)', style: const TextStyle(fontSize: 10))]);
      if (isPlayer1 && g1 == 7 && g2 == 6) return Row(mainAxisSize: MainAxisSize.min, children: [Text(score), Text('($tb2)', style: const TextStyle(fontSize: 10))]);
      if (!isPlayer1 && g2 == 6 && g1 == 7) return Row(mainAxisSize: MainAxisSize.min, children: [Text(score), Text('($tb2)', style: const TextStyle(fontSize: 10))]);
      if (!isPlayer1 && g2 == 7 && g1 == 6) return Row(mainAxisSize: MainAxisSize.min, children: [Text(score), Text('($tb1)', style: const TextStyle(fontSize: 10))]);
    }
    
    return Text(score, style: const TextStyle(fontSize: 16));
  }

  Widget _buildStatsDropdown(BuildContext context) {
    final numSets = widget.partido.estadisticas.values.first.estadisticasPorSet.length;
    final List<DropdownMenuItem<int>> items = [
      const DropdownMenuItem(value: 0, child: Text('Estadísticas Totales')),
      for (int i = 1; i <= numSets; i++)
        DropdownMenuItem(value: i, child: Text('Set ${i}')),
    ];

    return DropdownButton<int>(
      value: _selectedSet,
      items: items,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedSet = value;
          });
        }
      },
    );
  }

  Widget _buildStatsContent(BuildContext context) {
    if (_selectedSet == 0) {
      // Estadísticas Totales (Solo lectura con porcentajes)
      return Column(
        children: widget.partido.estadisticas.entries.map((entry) {
          final playerName = entry.key;
          final stats = entry.value.estadisticasTotales;
          return _buildStatsCard(context, playerName, stats);
        }).toList(),
      );
    } else {
      // Estadísticas por Set (Solo lectura por ahora para simplificar)
      final setIndex = _selectedSet - 1;
      return Column(
        children: widget.partido.estadisticas.entries.map((entry) {
          final playerName = entry.key;
          final stats = entry.value.estadisticasPorSet[setIndex];
          return _buildStatsCard(context, playerName, stats);
        }).toList(),
      );
    }
  }

  // Tarjeta editable para el dueño del partido
  Widget _buildEditableStatsCard(BuildContext context, String playerName, EstadisticaSet stats) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              playerName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildStatRowEditable('Aces', stats.aces, (d) => _updateStat(playerName, 'aces', d)),
            _buildStatRowEditable('Dobles Faltas', stats.doblesFaltas, (d) => _updateStat(playerName, 'doblesFaltas', d)),
            _buildStatRowEditable('Winners Drive', stats.winnersDrive, (d) => _updateStat(playerName, 'winnersDrive', d)),
            _buildStatRowEditable('Winners Revés', stats.winnersReves, (d) => _updateStat(playerName, 'winnersReves', d)),
            _buildStatRowEditable('Err. NF Drive', stats.erroresNoForzadosDrive, (d) => _updateStat(playerName, 'erroresNoForzadosDrive', d)),
            _buildStatRowEditable('Err. NF Revés', stats.erroresNoForzadosReves, (d) => _updateStat(playerName, 'erroresNoForzadosReves', d)),
            _buildStatRowEditable('Err. F Drive', stats.erroresForzadosDrive, (d) => _updateStat(playerName, 'erroresForzadosDrive', d)),
            _buildStatRowEditable('Err. F Revés', stats.erroresForzadosReves, (d) => _updateStat(playerName, 'erroresForzadosReves', d)),
            
            if (_customStatsConfig.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Personalizadas', style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              ..._customStatsConfig.map((config) => _buildCustomStatRow(playerName, config, stats)),
            ],
          ],
        ),
      ),
    );
  }

  // Tarjeta de solo lectura
  Widget _buildStatsCard(BuildContext context, String playerName, EstadisticaSet stats) {
    // Calcular totales para porcentajes
    final totalWinners = stats.winnersDrive + stats.winnersReves;
    final totalErrors = stats.erroresNoForzados + stats.erroresForzados;
    final totalServicios = stats.primerServicio + stats.segundoServicio;

    String formatPct(int value, int total) {
      final pct = total > 0 ? (value / total * 100) : 0.0;
      return '$value (${pct.toStringAsFixed(1)}%)';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              playerName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildStatRow('Primer Servicio', '${stats.primerServicio}/$totalServicios (${(totalServicios > 0 ? stats.primerServicio / totalServicios * 100 : 0).toStringAsFixed(1)}%)'),
            _buildStatRow('Segundo Servicio', '${stats.segundoServicio}/$totalServicios (${(totalServicios > 0 ? stats.segundoServicio / totalServicios * 100 : 0).toStringAsFixed(1)}%)'),
            _buildStatRow('Aces', stats.aces.toString()),
            _buildStatRow('Dobles Faltas', stats.doblesFaltas.toString()),
            _buildStatRow('Winners de Drive', formatPct(stats.winnersDrive, totalWinners)),
            _buildStatRow('Winners de Revés', formatPct(stats.winnersReves, totalWinners)),
            _buildStatRow('Err. No Forzados (Drive)', stats.erroresNoForzadosDrive.toString()),
            _buildStatRow('Err. No Forzados (Revés)', stats.erroresNoForzadosReves.toString()),
            _buildStatRow('Err. Forzados (Drive)', stats.erroresForzadosDrive.toString()),
            _buildStatRow('Err. Forzados (Revés)', stats.erroresForzadosReves.toString()),
            
            if (_customStatsConfig.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const Text('Personalizadas', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._customStatsConfig.expand((config) {
                final wonKey = '${config.id}_won';
                final lostKey = '${config.id}_lost';
                final wonVal = stats.customStats[wonKey] ?? 0;
                final lostVal = stats.customStats[lostKey] ?? 0;
                final total = wonVal + lostVal;
                final percentage = total > 0 ? (wonVal / total * 100) : 0.0;
                final errorPercentage = total > 0 ? (lostVal / total * 100) : 0.0;

                return [
                  _buildStatRow('${config.name} (Aciertos)', '$wonVal (${percentage.toStringAsFixed(1)}%)'),
                  _buildStatRow('${config.name} (Errores)', '$lostVal (${errorPercentage.toStringAsFixed(1)}%)'),
                ];
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRowEditable(String label, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
            onPressed: () => onChanged(-1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          SizedBox(
            width: 30,
            child: Text(
              value.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 20),
            onPressed: () => onChanged(1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomStatRow(String jugador, CustomStatConfig config, EstadisticaSet stats) {
    final wonKey = '${config.id}_won';
    final lostKey = '${config.id}_lost';
    final wonVal = stats.customStats[wonKey] ?? 0;
    final lostVal = stats.customStats[lostKey] ?? 0;
    final total = wonVal + lostVal;
    final percentage = total > 0 ? (wonVal / total * 100) : 0.0;
    final errorPercentage = total > 0 ? (lostVal / total * 100) : 0.0;
    final pctString = '(${percentage.toStringAsFixed(1)}%)';
    final errorPctString = '(${errorPercentage.toStringAsFixed(1)}%)';

    return Column(
      children: [
        _buildStatRowEditable('${config.name} (Aciertos) $pctString', wonVal, (d) => _updateStat(jugador, wonKey, d, isCustom: true)),
        _buildStatRowEditable('${config.name} (Errores) $errorPctString', lostVal, (d) => _updateStat(jugador, lostKey, d, isCustom: true)),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.getComments(_partidoOwnerId, _partidoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar comentarios: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No hay comentarios aún. ¡Sé el primero!'),
            ),
          );
        }

        final comments = snapshot.data!.docs;

        return Column(
          children: comments.map((doc) {
            final comment = doc.data() as Map<String, dynamic>;
            final authorEmail = comment['authorEmail'] ?? 'Anónimo';
            final text = comment['text'] ?? '';
            final isCurrentUser = comment['authorId'] == FirebaseService.currentUserId;

            return Align(
              alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                color: isCurrentUser ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceVariant,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorEmail,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(text),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCommentInputField(BuildContext context) {
    return Material(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Escribe un comentario...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                ),
                onSubmitted: (_) => _addComment(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _addComment,
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
