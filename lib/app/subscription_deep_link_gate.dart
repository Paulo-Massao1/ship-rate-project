import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/auth/login_page.dart';
import '../features/subscription/subscription_page.dart';

/// Keeps the subscription deep link behind authentication.
///
/// When a signed-out pilot opens `/assinar`, this widget displays the login
/// page and automatically reveals the plans as soon as authentication succeeds.
class SubscriptionDeepLinkGate extends StatelessWidget {
  const SubscriptionDeepLinkGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        if (snapshot.data != null) {
          return const SubscriptionPage();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A1628),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF64B5F6)),
            ),
          );
        }

        return const LoginPage();
      },
    );
  }
}
