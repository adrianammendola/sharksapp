import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late Future<List<QueryDocumentSnapshot>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = FirebaseService.getAllUsers();
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = FirebaseService.getAllUsers();
    });
  }

  void _showChangeRoleDialog(QueryDocumentSnapshot userDoc) {
    final userData = userDoc.data() as Map<String, dynamic>;
    final currentRole = userData['role'] ?? 'alumno';
    String selectedRole = currentRole;

    // Opciones de roles disponibles
    final List<String> availableRoles = ['alumno', 'profesor', 'admin'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Cambiar Rol de ${userData['email']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selecciona el nuevo rol:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: availableRoles.map((role) {
                  String roleName;
                  IconData roleIcon;
                  
                  switch (role) {
                    case 'admin':
                      roleName = 'Administrador';
                      roleIcon = Icons.admin_panel_settings;
                      break;
                    case 'profesor':
                      roleName = 'Profesor';
                      roleIcon = Icons.school;
                      break;
                    case 'alumno':
                    default:
                      roleName = 'Alumno';
                      roleIcon = Icons.person;
                      break;
                  }
                  
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Row(
                      children: [
                        Icon(roleIcon, size: 20),
                        const SizedBox(width: 8),
                        Text(roleName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setDialogState(() {
                      selectedRole = newValue;
                    });
                  }
                },
              ),
              if (selectedRole != currentRole) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cambiar de "$currentRole" a "$selectedRole"',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedRole == currentRole
                  ? null
                  : () async {
                      try {
                        await FirebaseService.updateUserRole(userDoc.id, selectedRole);
                        Navigator.of(context).pop();
                        _refreshUsers();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Rol actualizado a "$selectedRole" exitosamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al actualizar el rol: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar usuarios: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No se encontraron usuarios.'));
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userData = userDoc.data() as Map<String, dynamic>;
              final email = userData['email'] ?? 'Email no disponible';
              final role = userData['role'] ?? 'alumno';

              // Determinar icono y color según el rol
              IconData roleIcon;
              Color roleColor;
              String roleDisplayName;
              
              switch (role) {
                case 'admin':
                  roleIcon = Icons.admin_panel_settings;
                  roleColor = Colors.red;
                  roleDisplayName = 'Administrador';
                  break;
                case 'profesor':
                  roleIcon = Icons.school;
                  roleColor = Colors.blue;
                  roleDisplayName = 'Profesor';
                  break;
                case 'alumno':
                default:
                  roleIcon = Icons.person;
                  roleColor = Colors.green;
                  roleDisplayName = 'Alumno';
                  break;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: roleColor.withOpacity(0.1),
                    child: Icon(roleIcon, color: roleColor),
                  ),
                  title: Text(
                    email,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: roleColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(roleIcon, size: 14, color: roleColor),
                            const SizedBox(width: 4),
                            Text(
                              roleDisplayName,
                              style: TextStyle(
                                color: roleColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Cambiar rol',
                    onPressed: () => _showChangeRoleDialog(userDoc),
                  ),
                  onTap: () => _showChangeRoleDialog(userDoc),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
