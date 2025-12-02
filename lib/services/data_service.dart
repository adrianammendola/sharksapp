import 'package:hive_flutter/hive_flutter.dart';
import '../models/partido.dart';
import '../models/jugador.dart';
import 'firebase_service.dart';

class DataService {
  static final Box<Partido> _partidosBox = Hive.box<Partido>('partidos');
  static final Box<Jugador> _jugadoresBox = Hive.box<Jugador>('jugadores');

  // ========== JUGADORES ==========

  // Guardar jugador (local y nube)
  static Future<void> saveJugador(Jugador jugador) async {
    try {
      // Guardar localmente
      await _jugadoresBox.put(jugador.nombre, jugador);

      // Intentar sincronizar con Firebase
      await FirebaseService.saveJugador(jugador);
    } catch (e) {
      print('Error guardando jugador: $e');
      rethrow;
    }
  }

  // Obtener todos los jugadores
  static List<Jugador> getJugadores() {
    return _jugadoresBox.values.toList();
  }

  // Eliminar jugador
  static Future<void> deleteJugador(String nombre) async {
    try {
      // Eliminar localmente
      await _jugadoresBox.delete(nombre);

      // Intentar eliminar de Firebase
      await FirebaseService.deleteJugador(nombre);
    } catch (e) {
      print('Error eliminando jugador: $e');
      rethrow;
    }
  }

  // ========== PARTIDOS ==========

  // Guardar partido (local y nube)
  static Future<void> savePartido(Partido partido) async {
    try {
      // Guardar localmente
      final partidoId =
          '${partido.fecha.millisecondsSinceEpoch}_${partido.jugadores.join('_')}';
      await _partidosBox.put(partidoId, partido);

      // Intentar sincronizar con Firebase
      await FirebaseService.savePartido(partido);
    } catch (e) {
      print('Error guardando partido: $e');
      rethrow;
    }
  }

  // Obtener todos los partidos
  static List<Partido> getPartidos() {
    final partidos = _partidosBox.values.toList();
    partidos.sort((a, b) => b.fecha.compareTo(a.fecha));
    return partidos;
  }

  // Eliminar partido
  static Future<void> deletePartido(Partido partido) async {
    try {
      // Eliminar localmente
      final partidoId =
          '${partido.fecha.millisecondsSinceEpoch}_${partido.jugadores.join('_')}';
      await _partidosBox.delete(partidoId);

      // Intentar eliminar de Firebase
      await FirebaseService.deletePartido(partido);
    } catch (e) {
      print('Error eliminando partido: $e');
      rethrow;
    }
  }

  // ========== SINCRONIZACIÓN ==========

  // Sincronizar datos locales con Firebase
  static Future<void> syncToCloud() async {
    try {
      if (!await FirebaseService.hasInternetConnection()) {
        throw Exception('Sin conexión a internet');
      }

      final jugadores = getJugadores();
      final partidos = getPartidos();

      await FirebaseService.syncAllData(
        jugadores: jugadores,
        partidos: partidos,
      );

      print('Datos sincronizados exitosamente');
    } catch (e) {
      print('Error sincronizando datos: $e');
      rethrow;
    }
  }

  // Descargar datos de Firebase y guardar localmente
  static Future<void> downloadFromCloud() async {
    try {
      if (!await FirebaseService.hasInternetConnection()) {
        throw Exception('Sin conexión a internet');
      }

      final cloudData = await FirebaseService.downloadAllData();
      final jugadores = cloudData['jugadores'] as List<Jugador>;
      final partidos = cloudData['partidos'] as List<Partido>;

      // Limpiar datos locales
      await _jugadoresBox.clear();
      await _partidosBox.clear();

      // Guardar datos de la nube localmente
      for (final jugador in jugadores) {
        await _jugadoresBox.put(jugador.nombre, jugador);
      }

      for (final partido in partidos) {
        final partidoId =
            '${partido.fecha.millisecondsSinceEpoch}_${partido.jugadores.join('_')}';
        await _partidosBox.put(partidoId, partido);
      }

      print('Datos descargados exitosamente');
    } catch (e) {
      print('Error descargando datos: $e');
      rethrow;
    }
  }

  // ========== ESTADÍSTICAS ==========

  // Obtener estadísticas de un jugador
  static Map<String, dynamic> getJugadorStats(String nombreJugador) {
    final partidos = getPartidos();
    final partidosJugador = partidos
        .where((p) => p.jugadores.contains(nombreJugador))
        .toList();

    int partidosGanados = 0;
    int partidosPerdidos = 0;

    for (final partido in partidosJugador) {
      final rival = partido.jugadores.firstWhere((j) => j != nombreJugador);
      final setsJugador = partido.sets[nombreJugador] ?? 0;
      final setsRival = partido.sets[rival] ?? 0;

      if (setsJugador > setsRival) {
        partidosGanados++;
      } else {
        partidosPerdidos++;
      }
    }

    return {
      'partidosJugados': partidosJugador.length,
      'partidosGanados': partidosGanados,
      'partidosPerdidos': partidosPerdidos,
    };
  }

  // ========== UTILIDADES ==========

  // Verificar estado de conexión
  static Future<bool> hasInternetConnection() async {
    return await FirebaseService.hasInternetConnection();
  }

  // Obtener estado de sincronización
  static Future<Map<String, dynamic>> getSyncStatus() async {
    final hasInternet = await hasInternetConnection();
    final localJugadores = getJugadores().length;
    final localPartidos = getPartidos().length;

    int cloudJugadores = 0;
    int cloudPartidos = 0;

    if (hasInternet) {
      try {
        final cloudData = await FirebaseService.downloadAllData();
        cloudJugadores = (cloudData['jugadores'] as List).length;
        cloudPartidos = (cloudData['partidos'] as List).length;
      } catch (e) {
        print('Error obteniendo datos de la nube: $e');
      }
    }

    return {
      'hasInternet': hasInternet,
      'localJugadores': localJugadores,
      'localPartidos': localPartidos,
      'cloudJugadores': cloudJugadores,
      'cloudPartidos': cloudPartidos,
      'isSynced':
          hasInternet &&
          localJugadores == cloudJugadores &&
          localPartidos == cloudPartidos,
    };
  }
}
