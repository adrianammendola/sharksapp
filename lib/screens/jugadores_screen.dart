import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/jugador.dart';
import '../screens/jugador_perfil_screen.dart';
import '../screens/partidos_screen.dart';

class JugadoresScreen extends StatefulWidget {
  final String? userRole;
  const JugadoresScreen({super.key, required this.userRole});
  @override
  State<JugadoresScreen> createState() => _JugadoresScreenState();
}

class _JugadoresScreenState extends State<JugadoresScreen> {
  final Box<Jugador> jugadoresBox = Hive.box<Jugador>('jugadores');
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jugadores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sports_tennis),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PartidosScreen(userRole: widget.userRole)),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          double maxWidth = double.infinity;
          EdgeInsets padding = const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          );
          if (width >= 800) {
            maxWidth = 900;
            padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
          }
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ValueListenableBuilder(
                valueListenable: jugadoresBox.listenable(),
                builder: (context, Box<Jugador> box, _) {
                  final jugadores = box.values.toList();
                  return Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: constraints.maxWidth >= 800,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: padding,
                      itemCount: jugadores.length,
                      itemBuilder: (context, index) {
                        final jugador = jugadores[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              jugador.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    JugadorPerfilScreen(jugador: jugador),
                              ),
                            ),
                            trailing: IconButton(
                              tooltip: 'Eliminar',
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                jugador.delete();
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final nombre = await mostrarDialogoNuevoJugador(context);
          if (nombre != null && nombre.isNotEmpty) {
            final nuevoJugador = Jugador(nombre: nombre);
            jugadoresBox.add(nuevoJugador);
          }
        },
      ),
    );
  }

  Future<String?> mostrarDialogoNuevoJugador(BuildContext context) async {
    String nuevoNombre = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo jugador'),
        content: TextField(
          decoration: const InputDecoration(labelText: 'Nombre'),
          onChanged: (value) => nuevoNombre = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nuevoNombre),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}