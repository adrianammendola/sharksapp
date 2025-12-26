import 'package:flutter/material.dart';
import '../models/custom_stat_config.dart';
import '../services/data_service.dart';

class CustomStatsScreen extends StatefulWidget {
  const CustomStatsScreen({Key? key}) : super(key: key);

  @override
  State<CustomStatsScreen> createState() => _CustomStatsScreenState();
}

class _CustomStatsScreenState extends State<CustomStatsScreen> {
  List<CustomStatConfig> _stats = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    setState(() {
      _stats = DataService.getCustomStats();
    });
  }

  void _addStat() async {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      // Usamos timestamp como ID simple
      final newStat = CustomStatConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
      );
      await DataService.saveCustomStat(newStat);
      _controller.clear();
      _loadStats();
      if (mounted) Navigator.pop(context);
    }
  }

  void _deleteStat(String id) async {
    await DataService.deleteCustomStat(id);
    _loadStats();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Estadística'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ej: Volea, Smash, Drop Shot'),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ingrese nombre de la métrica',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),
            const Text(
              'Se crearán contadores de "Aciertos" y "Errores" para esta categoría.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _addStat,
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalizar Estadísticas'),
      ),
      body: _stats.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay estadísticas personalizadas',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text('Agrega métricas extra para tus partidos'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _stats.length,
              itemBuilder: (context, index) {
                final stat = _stats[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(stat.name.isNotEmpty ? stat.name[0].toUpperCase() : '?'),
                    ),
                    title: Text(stat.name),
                    subtitle: const Text('Registra: Ganados / Perdidos'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteStat(stat.id),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}