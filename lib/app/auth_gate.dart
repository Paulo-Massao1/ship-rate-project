import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../features/home/home_page.dart';
import '../features/auth/login_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Timer? _timeoutTimer;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _timedOut = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!StartupWidget.firebaseReady) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A1628),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    try {
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const LoginPage();
          }

          if (FirebaseAuth.instance.currentUser == null &&
              snapshot.data == null) {
            return const LoginPage();
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            if (_timedOut) {
              return const LoginPage();
            }
            return const Scaffold(
              backgroundColor: Color(0xFF0A1628),
              body: Center(child: CircularProgressIndicator(color: Colors.white)),
            );
          }

          _timeoutTimer?.cancel();

          if (snapshot.hasData) {
            return const HomePage();
          }

          return const LoginPage();
        },
      );
    } catch (e) {
      return const LoginPage();
    }
  }
}
