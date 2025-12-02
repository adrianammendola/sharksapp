import 'package:flutter/material.dart';
import '../models/jugador.dart';
import '../models/partido.dart';

class EditarEstadisticasScreen extends StatefulWidget {
  final Jugador jugador;
  final Partido partido;

  EditarEstadisticasScreen({required this.jugador, required this.partido});

  @override
  _EditarEstadisticasScreenState createState() =>
      _EditarEstadisticasScreenState();
}

class _EditarEstadisticasScreenState extends State<EditarEstadisticasScreen> {
  int primerServicio = 0;
  int puntosPrimerServicio = 0;
  int segundoServicio = 0;
  int puntosSegundoServicio = 0;
  int doblesFaltas = 0;

  int golpesDrive = 0;
  int golpesReves = 0;
  int erroresNoForzados = 0;
  int erroresForzados = 0;

  Widget _contador(String label, int valor, VoidCallback sumar, VoidCallback restar) {
    return Row(
      children: [
        Expanded(child: Text('$label: $valor')),
        IconButton(icon: Icon(Icons.remove), onPressed: restar),
        IconButton(icon: Icon(Icons.add), onPressed: sumar),
      ],
    );
  }

  void guardarEstadisticas() {
    widget.jugador.estadisticas.add({
      'fecha': widget.partido.fecha.toString(),
      'primerServicio': primerServicio,
      'puntosPrimerServicio': puntosPrimerServicio,
      'segundoServicio': segundoServicio,
      'puntosSegundoServicio': puntosSegundoServicio,
      'doblesFaltas': doblesFaltas,
      'golpesDrive': golpesDrive,
      'golpesReves': golpesReves,
      'erroresNoForzados': erroresNoForzados,
      'erroresForzados': erroresForzados,
    });
    widget.jugador.save();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Estadísticas - ${widget.jugador.nombre}')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Saque', style: TextStyle(fontWeight: FontWeight.bold)),
            _contador('Primer Servicio', primerServicio, () => setState(() => primerServicio++),
                () => setState(() => primerServicio--)),
            _contador('Puntos Primer Servicio', puntosPrimerServicio, () => setState(() => puntosPrimerServicio++),
                () => setState(() => puntosPrimerServicio--)),
            _contador('Segundo Servicio', segundoServicio, () => setState(() => segundoServicio++),
                () => setState(() => segundoServicio--)),
            _contador('Puntos Segundo Servicio', puntosSegundoServicio, () => setState(() => puntosSegundoServicio++),
                () => setState(() => puntosSegundoServicio--)),
            _contador('Dobles Faltas', doblesFaltas, () => setState(() => doblesFaltas++),
                () => setState(() => doblesFaltas--)),
            SizedBox(height: 16),
            Text('Golpes', style: TextStyle(fontWeight: FontWeight.bold)),
            _contador('Golpes ganadores Drive', golpesDrive, () => setState(() => golpesDrive++),
                () => setState(() => golpesDrive--)),
            _contador('Golpes ganadores Reves', golpesReves, () => setState(() => golpesReves++),
                () => setState(() => golpesReves--)),
            _contador('Errores No Forzados', erroresNoForzados, () => setState(() => erroresNoForzados++),
                () => setState(() => erroresNoForzados--)),
            _contador('Errores Forzados', erroresForzados, () => setState(() => erroresForzados++),
                () => setState(() => erroresForzados--)),
            SizedBox(height: 24),
            ElevatedButton(onPressed: guardarEstadisticas, child: Text('Guardar Estadísticas')),
          ],
        ),
      ),
    );
  }
}
