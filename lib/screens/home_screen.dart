import 'package:flutter/material.dart';
import 'package:tenis_shark_app/screens/pizarra_screen.dart';
import 'package:tenis_shark_app/screens/user_list_screen.dart';
import 'package:tenis_shark_app/services/firebase_service.dart';
import 'partidos_screen.dart';
import 'jugadores_screen.dart';
import 'registrar_partido_screen.dart';
import 'registrar_jugador_screen.dart';
import 'configuracion_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final role = await FirebaseService.getUserRole();
    if (mounted) {
      setState(() {
        _userRole = role;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final bool isAdmin = _userRole == 'admin';
    final bool isProfesor = _userRole == 'profesor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenis Sharks'),
        elevation: 0,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Configuración',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ConfiguracionScreen(),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await FirebaseService.signOut();
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          int crossAxisCount = width < 600 ? 2 : (width < 1024 ? 3 : 4);
          double maxWidth = width < 1024 ? 900 : 1100;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      '¡Bienvenido a Tenis Sharks!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                        children: [
                          _buildMenuCard(
                            context,
                            'Ver Partidos',
                            Icons.sports_tennis,
                            colorScheme.primary,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => PartidosScreen(userRole: _userRole)),
                            ),
                          ),
                          _buildMenuCard(
                            context,
                            'Ver Jugadores',
                            Icons.people,
                            colorScheme.primary,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => JugadoresScreen(userRole: _userRole)),
                            ),
                          ),
                          _buildMenuCard(
                            context,
                            'Registrar Partido',
                            Icons.add_circle,
                            colorScheme.primary,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegistrarPartidoScreen()),
                            ),
                          ),
                          _buildMenuCard(
                            context,
                            'Registrar Jugador',
                            Icons.person_add,
                            colorScheme.primary,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RegistrarJugadorScreen()),
                            ),
                          ),
                          if (isAdmin)
                            _buildMenuCard(
                              context,
                              'Gestionar Usuarios',
                              Icons.admin_panel_settings,
                              colorScheme.secondary,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const UserListScreen()),
                              ),
                            ),
                           if (isAdmin || isProfesor)
                            _buildMenuCard(
                              context,
                              'Pizarra de Tenis',
                              Icons.draw,
                              colorScheme.secondary,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const PizarraScreen()),
                              ),
                            ),
                        ],
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

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 6,
      shadowColor: color.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.95), color],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, size: 52, color: Colors.white.withOpacity(0.9)),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(1, 1))
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
