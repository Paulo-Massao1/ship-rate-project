import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/suggestion_service.dart';

/// Controller for suggestion/feedback submission.
///
/// Responsibilities:
/// - Validate suggestion input
/// - Submit suggestion to Firestore
/// - Get current user email
class SuggestionController {
  // ===========================================================================
  // DEPENDENCIES
  // ===========================================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===========================================================================
  // PUBLIC METHODS
  // ===========================================================================

  /// Gets the current user's email.
  String get currentUserEmail => _auth.currentUser?.email ?? '';

  /// Validates the suggestion message.
  ///
  /// Returns an error message if invalid, null if valid.
  String? validateMessage(String message) {
    if (message.trim().isEmpty) {
      return 'Por favor, escreva sua mensagem.';
    }
    return null;
  }

  /// Submits a suggestion to Firestore.
  ///
  /// Returns `true` if successful, `false` otherwise.
  Future<bool> submitSuggestion({
    required String type,
    required String message,
  }) async {
    return SuggestionService.send(
      email: currentUserEmail,
      title: type,
      message: message.trim(),
    );
  }
}