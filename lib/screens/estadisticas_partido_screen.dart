import 'package:flutter/material.dart';
import '../models/jugador.dart';
import '../models/custom_stat_config.dart';
import '../services/data_service.dart';

class EstadisticasPartidoScreen extends StatefulWidget {
  final Jugador jugador;
  const EstadisticasPartidoScreen({super.key, required this.jugador});

  @override
  State<EstadisticasPartidoScreen> createState() =>
      _EstadisticasPartidoScreenState();
}

class _EstadisticasPartidoScreenState extends State<EstadisticasPartidoScreen> {
  int primerServicio = 0;
  int puntosPrimerServicio = 0;
  int segundoServicio = 0;
  int puntosSegundoServicio = 0;
  int doblesFaltas = 0;
  int golpesDrive = 0;
  int golpesReves = 0;
  int erroresNoForzados = 0;
  int erroresForzados = 0;

  List<CustomStatConfig> _customStatsConfig = [];
  final Map<String, int> _customStatsValues = {};

  @override
  void initState() {
    super.initState();
    _loadCustomStats();
  }

  void _loadCustomStats() {
    setState(() {
      _customStatsConfig = DataService.getCustomStats();
    });
  }

  void guardarEstadisticas() {
    widget.jugador.estadisticas.add({
      'fecha': DateTime.now().toString(),
      'primerServicio': primerServicio,
      'puntosPrimerServicio': puntosPrimerServicio,
      'segundoServicio': segundoServicio,
      'puntosSegundoServicio': puntosSegundoServicio,
      'doblesFaltas': doblesFaltas,
      'golpesDrive': golpesDrive,
      'golpesReves': golpesReves,
      'erroresNoForzados': erroresNoForzados,
      'erroresForzados': erroresForzados,
      ..._customStatsValues,
    });

    widget.jugador.save();
    Navigator.pop(context);
  }

  Widget campoNumerico(String label, Function(int) onChanged) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      onChanged: (v) => onChanged(int.tryParse(v) ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cargar estadísticas')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final bool wide = width >= 920;
          final double maxWidth = wide ? 900 : double.infinity;
          final EdgeInsets pagePadding = const EdgeInsets.all(16);
          Widget form = Column(
            children: [
              campoNumerico('Primer servicio (%)', (v) => primerServicio = v),
              campoNumerico(
                'Puntos ganados primer servicio (%)',
                (v) => puntosPrimerServicio = v,
              ),
              campoNumerico('Segundo servicio (%)', (v) => segundoServicio = v),
              campoNumerico(
                'Puntos ganados segundo servicio (%)',
                (v) => puntosSegundoServicio = v,
              ),
              campoNumerico('Dobles faltas', (v) => doblesFaltas = v),
              campoNumerico('Golpes ganadores drive', (v) => golpesDrive = v),
              campoNumerico('Golpes ganadores revés', (v) => golpesReves = v),
              campoNumerico(
                'Errores no forzados',
                (v) => erroresNoForzados = v,
              ),
              campoNumerico('Errores forzados', (v) => erroresForzados = v),
              if (_customStatsConfig.isNotEmpty) ...[
                const SizedBox(height: 15),
                const Text('Estadísticas Personalizadas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ..._customStatsConfig.expand((config) {
                  final wonKey = '${config.id}_won';
                  final lostKey = '${config.id}_lost';
                  return [
                    campoNumerico('${config.name} (Aciertos)', (v) => _customStatsValues[wonKey] = v),
                    campoNumerico('${config.name} (Errores)', (v) => _customStatsValues[lostKey] = v),
                  ];
                }),
              ],
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: guardarEstadisticas,
                child: const Text('Guardar'),
              ),
            ],
          );

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: pagePadding,
                child: wide
                    ? Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [SizedBox(width: 430, child: form)],
                      )
                    : form,
              ),
            ),
          );
        },
      ),
    );
  }
}
