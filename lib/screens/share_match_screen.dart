import 'package:flutter/material.dart';
import 'package:tenis_shark_app/models/partido.dart';
import 'package:tenis_shark_app/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShareMatchScreen extends StatefulWidget {
  final Partido partido;

  const ShareMatchScreen({super.key, required this.partido});

  @override
  State<ShareMatchScreen> createState() => _ShareMatchScreenState();
}

class _ShareMatchScreenState extends State<ShareMatchScreen> {
  List<QueryDocumentSnapshot> _allUsers = [];
  final List<String> _selectedUserIds = [];
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadUsers();
  }

  Future<void> _loadUserRole() async {
    final role = await FirebaseService.getUserRole();
    setState(() {
      _userRole = role;
    });
  }

  Future<void> _loadUsers() async {
    try {
      final users = await FirebaseService.getAllUsers();
      setState(() {
        _allUsers = users;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar usuarios: $e')),
      );
    }
  }

  void _shareMatch() async {
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un usuario para compartir.')),
      );
      return;
    }

    // Verificar que el usuario actual es el dueño del partido
    final currentUserId = FirebaseService.currentUserId;
    final ownerId = widget.partido.ownerId ?? currentUserId;
    
    if (currentUserId != ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo el dueño del partido puede compartirlo.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar que el usuario tiene rol de profesor o administrador
    if (_userRole != 'profesor' && _userRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo profesores y administradores pueden compartir partidos.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (ownerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No se pudo identificar el propietario del partido.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final partidoId =
          '${widget.partido.fecha.millisecondsSinceEpoch}_${widget.partido.jugadores.join('_')}';
      await FirebaseService.shareMatch(ownerId, partidoId, _selectedUserIds);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partido compartido exitosamente!')),
      );
      Navigator.of(context).pop(); // Go back to match details
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al compartir partido: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compartir Partido'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _allUsers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _allUsers.length,
                    itemBuilder: (context, index) {
                      final user = _allUsers[index];
                      final userEmail = user['email'] as String;
                      final userId = user.id;

                      // No permitir compartir con uno mismo
                      if (userId == FirebaseService.currentUserId) {
                        return const SizedBox.shrink();
                      }

                      return CheckboxListTile(
                        title: Text(userEmail),
                        value: _selectedUserIds.contains(userId),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedUserIds.add(userId);
                            } else {
                              _selectedUserIds.remove(userId);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _shareMatch,
              child: const Text('Compartir'),
            ),
          ),
        ],
      ),
    );
  }
}
