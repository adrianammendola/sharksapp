import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models/partido.dart';
import 'package:flutter/gestures.dart';
import 'models/jugador.dart';
import 'models/estadistica_partido.dart';
import 'auth_wrapper.dart'; // Importar el AuthWrapper
import 'services/firebase_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseService.initialize();
  } catch (e) {
    print('Error inicializando Firebase: $e');
    // Continuar sin Firebase si hay error
  }

  // Inicializar Hive
  await Hive.initFlutter();

  // Registrar los adapters
  Hive.registerAdapter(PartidoAdapter());
  Hive.registerAdapter(JugadorAdapter());
  Hive.registerAdapter(EstadisticaPartidoAdapter());
  Hive.registerAdapter(EstadisticaSetAdapter());

  // Abrir las boxes donde se guardan los datos
  await Hive.openBox<Partido>('partidos');
  await Hive.openBox<Jugador>('jugadores');

  // Inicializar formateo de fechas para español
  try {
    await initializeDateFormatting('es_ES', null);
  } catch (e) {
    print('Error inicializando formato de fechas: $e');
    // Continuar aunque falle la inicialización
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definir la paleta de colores personalizada
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF145DA3),
      primary: const Color(0xFF145DA3),
      secondary: const Color(0xFF104D9B),
      surface: const Color(0xFFF0F2F5), // Un gris claro para el fondo
      onSurface: const Color(0xFF3E486C),
      error: Colors.redAccent,
      brightness: Brightness.light,
    );

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF145DA3),
      primary: const Color(0xFF145DA3),
      secondary: const Color(0xFF104D9B),
      surface: const Color(0xFF1A1A2E), // Un fondo oscuro
      onSurface: const Color(0xFFE0E0E0), // Texto claro para el modo oscuro
      error: Colors.redAccent,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Tenis Sharks',
      scrollBehavior: const _AppScrollBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: lightColorScheme.onSurface)
        ).copyWith(
          titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: lightColorScheme.primary,
          foregroundColor: lightColorScheme.onPrimary,
          centerTitle: false,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: darkColorScheme.onSurface)
        ).copyWith(
            titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: darkColorScheme.primary,
          foregroundColor: darkColorScheme.onPrimary,
          centerTitle: false,
        ),
      ),
      home: const AuthWrapper(), // Usar AuthWrapper como pantalla de inicio
      debugShowCheckedModeBanner: false,
    );
  }
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
