import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tenis_shark_app/models/estadistica_partido.dart';
import 'package:tenis_shark_app/models/partido.dart';
import 'package:tenis_shark_app/services/firebase_service.dart';
import 'package:tenis_shark_app/screens/share_match_screen.dart'; // Import the new screen
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
    if (_selectedSet == 0) {
      // Display total stats
      return Column(
        children: widget.partido.estadisticas.entries.map((entry) {
          final playerName = entry.key;
          final stats = entry.value.estadisticasTotales;
          return _buildStatsCard(context, playerName, stats);
        }).toList(),
      );
    } else {
      // Display stats for the selected set
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
          ],
        ),
      ),
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
