import 'package:flutter/material.dart';
import '../models/partido.dart';
import 'package:tenis_shark_app/services/firebase_service.dart';
import 'package:tenis_shark_app/screens/partido_detalle_screen.dart';

class PartidosScreen extends StatefulWidget {
  final String? userRole;
  const PartidosScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  State<PartidosScreen> createState() => _PartidosScreenState();
}

class _PartidosScreenState extends State<PartidosScreen> {
  final ScrollController _scrollController = ScrollController();

  List<String> _playerNamesFromPartido(Partido p) {
    return p.jugadores;
  }

  String _setsToText(Partido p) {
    return p.sets.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }

  Future<void> _deletePartido(Partido partido) async {
    try {
      await FirebaseService.deletePartido(partido);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partido eliminado exitosamente!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar partido: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.userRole == 'admin';

    return Scaffold(
      appBar: AppBar(title: Text(isAdmin ? 'Todos los Partidos' : 'Mis Partidos')),
      body: StreamBuilder<List<Partido>>(
        stream: isAdmin
            ? FirebaseService.listenToAllPartidosForAdmin()
            : FirebaseService.listenToPartidos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // Manejo mejorado de errores
          if (snapshot.hasError) {
            final errorMsg = snapshot.error.toString();
            print('Error capturado en PartidosScreen: $errorMsg');
            
            // Si es error de permisos, intentar solo mostrar partidos propios como fallback
            if (errorMsg.contains('permission-denied') || errorMsg.contains('permission denied')) {
              if (isAdmin) {
                // Si es admin y falla, mostrar mensaje claro
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          'Error de permisos',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Por favor, verifica que las reglas de Firestore estén desplegadas correctamente.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}), // Reintentar
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                // Para usuarios normales, intentar solo sus partidos propios
                return _buildPartidosList(
                  FirebaseService.listenToPartidos(),
                  isAdmin,
                );
              }
            }
            
            // Error de índice
            if (errorMsg.toLowerCase().contains('index')) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Error de base de datos: Falta un índice compuesto en Firestore. Por favor, revisa la consola de Flutter/Firebase para encontrar un enlace para crearlo automáticamente.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            
            // Otro error
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $errorMsg'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}), // Reintentar
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay partidos registrados.'));
          }

          final partidos = snapshot.data!;
          return _buildPartidosListContent(partidos);
        },
      ),
    );
  }

  Widget _buildPartidosList(Stream<List<Partido>> stream, bool isAdmin) {
    return StreamBuilder<List<Partido>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay partidos registrados.'));
        }
        return _buildPartidosListContent(snapshot.data!);
      },
    );
  }

  Widget _buildPartidosListContent(List<Partido> partidos) {
    return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              double maxWidth = double.infinity;
              EdgeInsets padding = const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              );
              if (width >= 800) {
                maxWidth = 900;
                padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
              }
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: width >= 800,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: partidos.length,
                      itemBuilder: (context, i) {
                        final p = partidos[i];
                        final names = _playerNamesFromPartido(p);
                        final title = names.join(' vs ');
                        final setsText = _setsToText(p);
                        final dateStr = p.fecha.toLocal().toString().split(' ')[0];

                        return Padding(
                          padding: padding,
                          child: Card(
                            elevation: 2,
                            child: ListTile(
                              title: Text(
                                title,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text('$setsText  •  $dateStr'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PartidoDetalleScreen(partido: p),
                                  ),
                                );
                              },
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Eliminar',
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deletePartido(p),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
  }
}