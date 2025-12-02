import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/jugador.dart';
import '../models/partido.dart';
import 'package:rxdart/rxdart.dart'; // Import rxdart

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Colecciones
  static const String _usersCollection = 'users';
  static const String _jugadoresCollection = 'jugadores';
  static const String _partidosCollection = 'partidos';
  static const String _commentsCollection = 'comments';

  // ========== AUTHENTICATION ==========

  // Stream para escuchar cambios en el estado de autenticación
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual
  static User? get currentUser => _auth.currentUser;
  static String? get currentUserId => _auth.currentUser?.uid;

  // Iniciar sesión con email y contraseña
  static Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print('Error en signIn: $e');
      rethrow;
    }
  }

  // Registrar un nuevo usuario con email y contraseña
  static Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print('Error en createUser: $e');
      rethrow;
    }
  }

  // Crea el perfil de usuario en Firestore después del registro
  static Future<void> createUserProfile(User user) async {
    try {
      await _firestore.collection(_usersCollection).doc(user.uid).set({
        'email': user.email,
        'role': 'alumno', // Rol por defecto
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creando el perfil de usuario: $e');
      rethrow;
    }
  }

  // Cerrar sesión
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error en signOut: $e');
      rethrow;
    }
  }


  // Inicializar Firebase (ya no hace signIn anónimo)
  static Future<void> initialize() async {
    // El initializeApp se hace en main.dart
    // Este método puede usarse para futuras configuraciones si es necesario.
  }

  // ========== USER MANAGEMENT ==========

  // Obtener el rol del usuario actual
  static Future<String?> getUserRole() async {
    if (currentUserId == null) return null;
    try {
      final doc = await _firestore.collection(_usersCollection).doc(currentUserId).get();
      return doc.data()?['role'];
    } catch (e) {
      print('Error obteniendo el rol del usuario: $e');
      return null;
    }
  }

  // Obtener todos los perfiles de usuario (solo para admin)
  static Future<List<QueryDocumentSnapshot>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection(_usersCollection).get();
      return snapshot.docs;
    } catch (e) {
      print('Error obteniendo todos los usuarios: $e');
      rethrow;
    }
  }

  // Actualizar el rol de un usuario (solo para admin)
  static Future<void> updateUserRole(String uid, String newRole) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'role': newRole,
      });
    } catch (e) {
      print('Error actualizando el rol del usuario: $e');
      rethrow;
    }
  }

  // ========== JUGADORES ==========

  // Guardar jugador en Firebase
  static Future<void> saveJugador(Jugador jugador) async {
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection(_jugadoresCollection)
          .doc(jugador.nombre)
          .set(jugador.toJson());
    } catch (e) {
      print('Error guardando jugador: $e');
      rethrow;
    }
  }

  // Obtener todos los jugadores
  static Future<List<Jugador>> getJugadores() async {
    if (currentUserId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection(_jugadoresCollection)
          .get();

      return snapshot.docs.map((doc) => Jugador.fromJson(doc.data())).toList();
    } catch (e) {
      print('Error obteniendo jugadores: $e');
      return [];
    }
  }

  // Eliminar jugador
  static Future<void> deleteJugador(String nombre) async {
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection(_jugadoresCollection)
          .doc(nombre)
          .delete();
    } catch (e) {
      print('Error eliminando jugador: $e');
      rethrow;
    }
  }

  // ========== PARTIDOS ==========

  // ========== COMMENTS ==========

  // Obtener stream de comentarios para un partido
  static Stream<QuerySnapshot> getComments(String userId, String partidoId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_partidosCollection)
        .doc(partidoId)
        .collection(_commentsCollection)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Añadir un comentario a un partido
  static Future<void> addComment(String userId, String partidoId, String commentText) async {
    if (currentUser == null) return; // Solo usuarios logueados pueden comentar

    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_partidosCollection)
          .doc(partidoId)
          .collection(_commentsCollection)
          .add({
        'text': commentText,
        'authorId': currentUser!.uid,
        'authorEmail': currentUser!.email,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error añadiendo comentario: $e');
      rethrow;
    }
  }

  // Compartir un partido con otros usuarios
  static Future<void> shareMatch(String ownerId, String partidoId, List<String> userIdsToShareWith) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(ownerId)
          .collection(_partidosCollection)
          .doc(partidoId)
          .update({
        'sharedWith': FieldValue.arrayUnion(userIdsToShareWith),
      });
    } catch (e) {
      print('Error compartiendo partido: $e');
      rethrow;
    }
  }

  // Guardar partido en Firebase
  static Future<void> savePartido(Partido partido) async {
    if (currentUserId == null) return;

    try {
      final partidoId =
          '${partido.fecha.millisecondsSinceEpoch}_${partido.jugadores.join('_')}';

      // Usar ownerId del partido si existe, sino usar currentUserId
      final ownerId = partido.ownerId ?? currentUserId;
      
      // Crear un mapa con ownerId incluido
      final partidoData = partido.toJson();
      partidoData['ownerId'] = ownerId;

      await _firestore
          .collection('users')
          .doc(ownerId)
          .collection(_partidosCollection)
          .doc(partidoId)
          .set(partidoData);
    } catch (e) {
      print('Error guardando partido: $e');
      rethrow;
    }
  }

  // Obtener todos los partidos
  static Future<List<Partido>> getPartidos() async {
    if (currentUserId == null) return [];

    try {
      // 1. Obtener partidos propios
      final ownedMatchesSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection(_partidosCollection)
          .orderBy('fecha', descending: true)
          .get();

      List<Partido> allMatches = ownedMatchesSnapshot.docs
          .map((doc) => Partido.fromJson(doc.data()))
          .toList();

      // 2. Obtener partidos compartidos con el usuario actual
      // Esto requiere buscar en todos los documentos de partidos de todos los usuarios
      // donde 'sharedWith' contenga el currentUserId.
      // Nota: Esta consulta puede ser costosa si hay muchos usuarios y partidos.
      // Una alternativa más escalable sería tener una subcolección 'sharedWithMe' en cada usuario.
      final sharedMatchesSnapshot = await _firestore
          .collectionGroup(_partidosCollection) // Busca en todas las subcolecciones de partidos
          .where('sharedWith', arrayContains: currentUserId)
          .orderBy('fecha', descending: true)
          .get();
      
      for (var doc in sharedMatchesSnapshot.docs) {
        final partido = Partido.fromJson(doc.data());
        // Evitar duplicados si un partido es propio y también compartido
        if (!allMatches.any((p) => p.fecha == partido.fecha && p.jugadores.join('_') == partido.jugadores.join('_'))) {
          allMatches.add(partido);
        }
      }

      // Ordenar la lista combinada por fecha
      allMatches.sort((a, b) => b.fecha.compareTo(a.fecha));

      return allMatches;
    } catch (e) {
      print('Error obteniendo partidos: $e');
      return [];
    }
  }

  // Eliminar partido
  static Future<void> deletePartido(Partido partido) async {
    if (currentUserId == null) return;

    try {
      final partidoId =
          '${partido.fecha.millisecondsSinceEpoch}_${partido.jugadores.join('_')}';

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection(_partidosCollection)
          .doc(partidoId)
          .delete();
    } catch (e) {
      print('Error eliminando partido: $e');
      rethrow;
    }
  }

  // ========== SINCRONIZACIÓN ==========

  // Sincronizar todos los datos locales con Firebase
  static Future<void> syncAllData({
    required List<Jugador> jugadores,
    required List<Partido> partidos,
  }) async {
    if (currentUserId == null) return;

    try {
      // Sincronizar jugadores
      for (final jugador in jugadores) {
        await saveJugador(jugador);
      }

      // Sincronizar partidos
      for (final partido in partidos) {
        await savePartido(partido);
      }
    } catch (e) {
      print('Error sincronizando datos: $e');
      rethrow;
    }
  }

  // Descargar todos los datos de Firebase
  static Future<Map<String, dynamic>> downloadAllData() async {
    if (currentUserId == null) return {'jugadores': [], 'partidos': []};

    try {
      final jugadores = await getJugadores();
      final partidos = await getPartidos();

      return {'jugadores': jugadores, 'partidos': partidos};
    } catch (e) {
      print('Error descargando datos: $e');
      return {'jugadores': [], 'partidos': []};
    }
  }

  // ========== ESTADO DE CONEXIÓN ==========

  // Verificar si hay conexión a internet
  static Future<bool> hasInternetConnection() async {
    try {
      // Intenta una lectura que las reglas deben permitir en producción
      await _firestore.collectionGroup(_partidosCollection).limit(1).get();
      return true; // si hay conexión y permisos mínimos
    } catch (e) {
      return false;
    }
  }

  // Escuchar cambios en tiempo real
  static Stream<List<Jugador>> listenToJugadores() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection(_jugadoresCollection)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Jugador.fromJson(doc.data())).toList(),
        );
  }

  static Stream<List<Partido>> listenToAllPartidosForAdmin() {
    if (currentUserId == null) return Stream.value([]);
    
    // Alternativa: Obtener todos los usuarios y crear streams para cada uno
    // Luego combinar todos los streams de partidos
    return _firestore.collection(_usersCollection).snapshots().switchMap((usersSnapshot) {
      if (usersSnapshot.docs.isEmpty) {
        return Stream.value(<Partido>[]);
      }
      
      // Crear un stream para cada usuario
      final streams = usersSnapshot.docs.map((userDoc) {
        return _firestore
            .collection(_usersCollection)
            .doc(userDoc.id)
            .collection(_partidosCollection)
            .orderBy('fecha', descending: true)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) {
                  try {
                    return Partido.fromJson(doc.data());
                  } catch (e) {
                    print('Error parseando partido ${doc.id}: $e');
                    return null;
                  }
                })
                .whereType<Partido>()
                .toList());
      });
      
      // Combinar todos los streams
      if (streams.isEmpty) {
        return Stream.value(<Partido>[]);
      }
      
      return Rx.combineLatestList(streams).map((listOfPartidosLists) {
        // Aplanar la lista de listas y ordenar
        final allPartidos = <Partido>[];
        for (var partidosList in listOfPartidosLists) {
          allPartidos.addAll(partidosList);
        }
        allPartidos.sort((a, b) => b.fecha.compareTo(a.fecha));
        return allPartidos;
      });
    });
  }

  static Stream<List<Partido>> listenToPartidos() {
    if (currentUserId == null) return Stream.value([]);

    // Stream de partidos propios
    final ownedMatchesStream = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection(_partidosCollection)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Partido.fromJson(doc.data())).toList());

    // Stream de partidos compartidos
    final sharedMatchesStream = _firestore
        .collectionGroup(_partidosCollection)
        .where('sharedWith', arrayContains: currentUserId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Partido.fromJson(doc.data())).toList());

    // Combinar ambos streams usando rxdart
    return Rx.combineLatest2(ownedMatchesStream, sharedMatchesStream,
        (List<Partido> ownedMatches, List<Partido> sharedMatches) {
      List<Partido> allMatches = [...ownedMatches];
      for (var partido in sharedMatches) {
        // Evitar duplicados si un partido es propio y también compartido
        if (!allMatches.any((p) => p.fecha == partido.fecha && p.jugadores.join('_') == partido.jugadores.join('_'))) {
          allMatches.add(partido);
        }
      }
      allMatches.sort((a, b) => b.fecha.compareTo(a.fecha));
      return allMatches;
    });
  }
}
