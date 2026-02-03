import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Controller responsible for authentication and user management.
///
/// Centralizes all authentication logic (login, register, logout, password reset),
/// abstracting Firebase Authentication and Firestore layers.
///
/// Firestore user document structure (`usuarios/{uid}`):
/// - email: User's email
/// - nomeGuerra: Call sign (public identifier in the app)
/// - createdAt: Account creation timestamp
///
/// Error handling:
/// Methods convert Firebase errors to user-friendly messages via [AuthException].
class AuthController {
  // ===========================================================================
  // DEPENDENCIES
  // ===========================================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  static const String _usersCollection = 'usuarios';

  // ===========================================================================
  // PUBLIC METHODS
  // ===========================================================================

  /// Registers a new user.
  ///
  /// Creates a Firebase Auth account and saves additional data to Firestore.
  ///
  /// Parameters:
  /// - [email]: User's email address
  /// - [password]: User's password
  /// - [confirmPassword]: Password confirmation
  /// - [callSign]: User's call sign (public identifier)
  ///
  /// Throws [AuthException] on validation errors or Firebase failures.
  Future<void> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String callSign,
  }) async {
    _validateRegistrationFields(email, password, confirmPassword, callSign);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _saveUserData(userCredential.user!.uid, email, callSign);
    } on FirebaseAuthException catch (error) {
      throw AuthException(error.message ?? 'Erro ao cadastrar usuário.');
    }
  }

  /// Authenticates user with email and password.
  ///
  /// Throws [AuthException] with user-friendly messages for common errors.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    _validateLoginFields(email, password);

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (error) {
      debugPrint('🔐 FirebaseAuth login error: ${error.code} - ${error.message}');
      throw AuthException(_mapLoginError(error.code));
    }
  }

  /// Signs out the current user.
  ///
  /// Invalidates the session. Navigation to login is handled by AuthGate.
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Sends a password reset email.
  ///
  /// Uses Firebase's built-in password reset flow.
  /// Note: Does not return error if email doesn't exist (security measure).
  ///
  /// Throws [AuthException] on failure.
  Future<void> sendPasswordReset(String email) async {
    if (email.isEmpty) {
      throw AuthException('Informe o e-mail.');
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      throw AuthException(error.message ?? 'Erro ao enviar e-mail.');
    }
  }

  // ===========================================================================
  // PRIVATE METHODS
  // ===========================================================================

  /// Validates registration form fields.
  void _validateRegistrationFields(
    String email,
    String password,
    String confirmPassword,
    String callSign,
  ) {
    if (email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        callSign.isEmpty) {
      throw AuthException('Preencha todos os campos.');
    }

    if (password != confirmPassword) {
      throw AuthException('As senhas não coincidem.');
    }
  }

  /// Validates login form fields.
  void _validateLoginFields(String email, String password) {
    if (email.isEmpty || password.isEmpty) {
      throw AuthException('Preencha todos os campos.');
    }
  }

  /// Saves user data to Firestore.
  Future<void> _saveUserData(String uid, String email, String callSign) async {
    await _firestore.collection(_usersCollection).doc(uid).set({
      'email': email,
      'nomeGuerra': callSign,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Maps Firebase error codes to user-friendly messages.
  String _mapLoginError(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return 'O e-mail informado é inválido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'user-not-found':
        return 'Nenhuma conta encontrada com este e-mail.';
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'E-mail ou senha incorretos. Tente novamente.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos.';
      default:
        return 'Não foi possível realizar o login. Verifique suas credenciais.';
    }
  }
}

/// Custom exception for authentication errors.
///
/// Provides user-friendly messages for UI display.
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}