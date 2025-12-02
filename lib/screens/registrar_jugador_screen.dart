import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/jugador.dart';

class RegistrarJugadorScreen extends StatefulWidget {
  @override
  _RegistrarJugadorScreenState createState() => _RegistrarJugadorScreenState();
}

class _RegistrarJugadorScreenState extends State<RegistrarJugadorScreen> {
  final TextEditingController nombreController = TextEditingController();
  final Box<Jugador> jugadoresBox = Hive.box<Jugador>('jugadores');

  void _guardarJugador() {
    final nombre = nombreController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('El nombre no puede estar vacío')));
      return;
    }

    final existe = jugadoresBox.values.any(
      (j) => j.nombre.toLowerCase() == nombre.toLowerCase(),
    );
    if (existe) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('El jugador ya existe')));
      return;
    }

    final nuevoJugador = Jugador(nombre: nombre);
    jugadoresBox.add(nuevoJugador);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Jugador agregado')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Agregar Jugador')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final double maxWidth = width >= 920 ? 600 : double.infinity;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del jugador',
                      ),
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _guardarJugador,
                        child: Text('Guardar jugador'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
