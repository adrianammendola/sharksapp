import 'package:flutter/material.dart';
import '../services/data_service.dart';
import 'custom_stats_screen.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({Key? key}) : super(key: key);

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _syncStatus = {};

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    final status = await DataService.getSyncStatus();
    setState(() {
      _syncStatus = status;
    });
  }

  Future<void> _syncToCloud() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await DataService.syncToCloud();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos sincronizados exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sincronizando: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      _loadSyncStatus();
    }
  }

  Future<void> _downloadFromCloud() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await DataService.downloadFromCloud();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos descargados exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error descargando: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      _loadSyncStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración y Sincronización'),
        // El color se toma del tema general
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = constraints.maxWidth > 900 ? 900 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildConnectionStatusCard(context, colorScheme),
                    const SizedBox(height: 16),
                    _buildCustomStatsCard(context, colorScheme),
                    const SizedBox(height: 16),
                    _buildSyncStatusCard(context, colorScheme),
                    const SizedBox(height: 16),
                    if (_syncStatus['hasInternet'] == true)
                      _buildSyncButtons(context, colorScheme)
                    else
                      _buildInfoCard(
                        context,
                        'Conecta a internet para sincronizar tus datos',
                        Icons.wifi_off,
                        colorScheme.errorContainer,
                        colorScheme.onErrorContainer,
                      ),
                    const SizedBox(height: 24),
                    _buildInfoCard(
                      context,
                      '• Tus datos se guardan localmente y se sincronizan con la nube.\n'
                      '• Puedes usar la app sin internet; los cambios se subirán al conectarte.\n'
                      '• Cada usuario tiene sus propios datos privados.',
                      Icons.info_outline,
                      colorScheme.primaryContainer,
                      colorScheme.onPrimaryContainer,
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

  Widget _buildConnectionStatusCard(BuildContext context, ColorScheme colorScheme) {
    final bool hasInternet = _syncStatus['hasInternet'] == true;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(
          hasInternet ? Icons.wifi : Icons.wifi_off,
          color: hasInternet ? colorScheme.primary : colorScheme.error,
        ),
        title: Text(
          hasInternet ? 'Conectado a Internet' : 'Sin conexión a Internet',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(hasInternet
            ? 'La sincronización está activa'
            : 'Los datos se guardan solo en este dispositivo'),
      ),
    );
  }

  Widget _buildCustomStatsCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(Icons.bar_chart, color: colorScheme.primary),
        title: const Text('Estadísticas Personalizadas'),
        subtitle: const Text('Define qué métricas quieres registrar'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CustomStatsScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSyncStatusCard(BuildContext context, ColorScheme colorScheme) {
    final bool isSynced = _syncStatus['isSynced'] == true;
    final syncColor = isSynced ? Colors.green.shade700 : colorScheme.secondary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado de Sincronización',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 24),
            _buildSyncRow(
              'Jugadores locales',
              _syncStatus['localJugadores']?.toString() ?? '-',
            ),
            _buildSyncRow(
              'Jugadores en la nube',
              _syncStatus['cloudJugadores']?.toString() ?? '-',
            ),
            const SizedBox(height: 8),
            _buildSyncRow(
              'Partidos locales',
              _syncStatus['localPartidos']?.toString() ?? '-',
            ),
            _buildSyncRow(
              'Partidos en la nube',
              _syncStatus['cloudPartidos']?.toString() ?? '-',
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(
                  isSynced ? Icons.check_circle : Icons.sync_problem,
                  color: syncColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isSynced ? 'Datos Sincronizados' : 'Datos Desincronizados',
                  style: TextStyle(
                    color: syncColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncButtons(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _syncToCloud,
          icon: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
              : const Icon(Icons.cloud_upload),
          label: Text(_isLoading ? 'Sincronizando...' : 'Subir a la Nube'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _downloadFromCloud,
          icon: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.cloud_download),
          label: Text(_isLoading ? 'Descargando...' : 'Descargar de la Nube'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.secondary,
            foregroundColor: colorScheme.onSecondary,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, String text, IconData icon, Color backgroundColor, Color foregroundColor) {
    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: foregroundColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
