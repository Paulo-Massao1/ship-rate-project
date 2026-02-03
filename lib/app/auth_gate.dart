import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/home/main_screen_page.dart';
import '../features/auth/login_page.dart';

/// Authentication gate that controls app navigation based on auth state.
///
/// Acts as the entry point that listens to Firebase auth state changes
/// and automatically redirects users to the appropriate screen:
/// - [MainScreen]: When authenticated
/// - [LoginPage]: When not authenticated
///
/// Benefits:
/// - Eliminates manual navigation after login/logout
/// - Prevents UI flicker on app startup
/// - Ensures consistent security and UX
/// - Auto-syncs with auth state changes
///
/// Usage in main.dart:
/// ```dart
/// MaterialApp(home: const AuthGate())
/// ```
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state - checking authentication
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Authenticated - show main screen
        if (snapshot.hasData) {
          return const MainScreen();
        }

        // Not authenticated - show login
        return const LoginPage();
      },
    );
  }
}