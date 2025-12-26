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
    setState(() {
      _customStatsConfig = DataService.getCustomStats();
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
          case 'erroresNoForzados':
            totalStats.erroresNoForzados = (totalStats.erroresNoForzados + delta).clamp(0, 999);
            break;
          case 'erroresForzados':
            totalStats.erroresForzados = (totalStats.erroresForzados + delta).clamp(0, 999);
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              widget.partido.jugadores.join(' vs '),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(widget.partido.fecha),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              widget.partido.sets.entries.map((e) => e.value).join(' - '),
              style: Theme.of(context).textTheme.headlineMedium,
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
    // Verificar si el usuario puede editar (es el dueño)
    final isOwner = FirebaseService.currentUserId == (widget.partido.ownerId ?? FirebaseService.currentUserId);

    if (_selectedSet == 0) {
      // Estadísticas Totales (Editables si es el dueño)
      return Column(
        children: widget.partido.estadisticas.entries.map((entry) {
          final playerName = entry.key;
          final stats = entry.value.estadisticasTotales;
          return isOwner 
              ? _buildEditableStatsCard(context, playerName, stats)
              : _buildStatsCard(context, playerName, stats);
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
            _buildStatRowEditable('Err. No Forzados', stats.erroresNoForzados, (d) => _updateStat(playerName, 'erroresNoForzados', d)),
            _buildStatRowEditable('Err. Forzados', stats.erroresForzados, (d) => _updateStat(playerName, 'erroresForzados', d)),
            
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
            _buildStatRow('Primer Servicio', '${stats.porcentajePrimerServicio.toStringAsFixed(1)}%'),
            _buildStatRow('Segundo Servicio', '${stats.porcentajeSegundoServicio.toStringAsFixed(1)}%'),
            _buildStatRow('Aces', stats.aces.toString()),
            _buildStatRow('Dobles Faltas', stats.doblesFaltas.toString()),
            _buildStatRow('Winners de Drive', stats.winnersDrive.toString()),
            _buildStatRow('Winners de Revés', stats.winnersReves.toString()),
            _buildStatRow('Errores No Forzados', stats.erroresNoForzados.toString()),
            _buildStatRow('Errores Forzados', stats.erroresForzados.toString()),
            
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
