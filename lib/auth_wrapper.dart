
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tenis_shark_app/screens/home_screen.dart';
import 'package:tenis_shark_app/screens/login_screen.dart';
import 'package:tenis_shark_app/services/firebase_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseService.authStateChanges,
      builder: (context, snapshot) {
        // Muestra un indicador de carga mientras se conecta
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Si el usuario ha iniciado sesión, muestra la pantalla principal
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // Si no, muestra la pantalla de login
        return const LoginScreen();
      },
    );
  }
}
