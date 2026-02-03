import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for saving user suggestions to Firestore.
///
/// Abstracts the process of persisting user feedback, suggestions,
/// and complaints to a dedicated Firestore collection.
///
/// Firestore document structure:
/// ```json
/// {
///   "email": "user@example.com",
///   "title": "Suggestion",
///   "message": "The search could be faster",
///   "createdAt": <server_timestamp>
/// }
/// ```
class SuggestionService {
  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  /// Firestore collection name for suggestions.
  /// Kept as 'sugestoes' for backwards compatibility.
  static const String _collectionName = 'sugestoes';

  // ===========================================================================
  // PUBLIC METHODS
  // ===========================================================================

  /// Sends a suggestion to Firestore.
  ///
  /// Parameters:
  /// - [email]: User's email address
  /// - [title]: Type of feedback (Sugestão, Crítica, Elogio)
  /// - [message]: The actual feedback content
  ///
  /// Returns `true` if saved successfully, `false` otherwise.
  static Future<bool> send({
    required String email,
    required String title,
    required String message,
  }) async {
    try {
      await FirebaseFirestore.instance.collection(_collectionName).add({
        'email': email,
        'title': title,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (error) {
      debugPrint('❌ Error saving suggestion: $error');
      return false;
    }
  }
}