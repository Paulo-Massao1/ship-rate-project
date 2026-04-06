import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Controller for the Navigation Safety module.
///
/// Responsibilities:
/// - Fetch all locations with their most recent registro
/// - Fetch all registros for a specific location
/// - Manage selected location state
class NavSafetyController extends ChangeNotifier {
  // ===========================================================================
  // DEPENDENCIES
  // ===========================================================================

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===========================================================================
  // CONSTANTS
  // ===========================================================================

  static const String _locationsCollection = 'locais';
  static const String _recordsSubcollection = 'registros';

  // ===========================================================================
  // STATE
  // ===========================================================================

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<LocationWithLatestRecord> _locations = [];
  List<LocationWithLatestRecord> get locations => _locations;

  String? _selectedLocationId;
  String? get selectedLocationId => _selectedLocationId;

  String? _selectedLocationName;
  String? get selectedLocationName => _selectedLocationName;

  bool _isLoadingHistory = false;
  bool get isLoadingHistory => _isLoadingHistory;

  List<Map<String, dynamic>> _locationRecords = [];
  List<Map<String, dynamic>> get locationRecords => _locationRecords;

  // ===========================================================================
  // PUBLIC METHODS
  // ===========================================================================

  /// Fetches all locations with their most recent registro.
  Future<void> fetchLocationsWithLatestRecord() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection(_locationsCollection)
          .orderBy('nome')
          .get();

      final results = <LocationWithLatestRecord>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = (data['nome'] ?? '').toString();

        final latestSnapshot = await doc.reference
            .collection(_recordsSubcollection)
            .orderBy('data', descending: true)
            .limit(1)
            .get();

        Map<String, dynamic>? latestRecord;
        if (latestSnapshot.docs.isNotEmpty) {
          latestRecord = latestSnapshot.docs.first.data();
        }

        results.add(LocationWithLatestRecord(
          id: doc.id,
          name: name,
          latestRecord: latestRecord,
        ));
      }

      _locations = results;
    } catch (e) {
      debugPrint('[NavSafety] Error fetching locations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches all registros for a specific location.
  Future<void> fetchLocationHistory(String locationId, String locationName) async {
    _selectedLocationId = locationId;
    _selectedLocationName = locationName;
    _isLoadingHistory = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection(_locationsCollection)
          .doc(locationId)
          .collection(_recordsSubcollection)
          .orderBy('data', descending: true)
          .get();

      _locationRecords = snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('[NavSafety] Error fetching history: $e');
      _locationRecords = [];
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Creates a new location document and returns its ID.
  Future<String> addLocation(String name) async {
    final doc = await _firestore.collection(_locationsCollection).add({
      'nome': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Saves a new record to the registros subcollection of a location.
  Future<void> saveRecord(String locationId, Map<String, dynamic> data) async {
    await _firestore
        .collection(_locationsCollection)
        .doc(locationId)
        .collection(_recordsSubcollection)
        .add(data);
  }

  /// Clears the selected location and returns to the list view.
  void clearSelection() {
    _selectedLocationId = null;
    _selectedLocationName = null;
    _locationRecords = [];
    notifyListeners();
  }

  /// Fetches all records belonging to the current user across all locations.
  Future<List<MyRecord>> fetchMyRecords() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return [];

    try {
      final locSnapshot = await _firestore
          .collection(_locationsCollection)
          .orderBy('nome')
          .get();

      final results = <MyRecord>[];

      for (final locDoc in locSnapshot.docs) {
        final locationName = (locDoc.data()['nome'] ?? '').toString();
        final recordsSnapshot = await locDoc.reference
            .collection(_recordsSubcollection)
            .where('pilotId', isEqualTo: uid)
            .orderBy('data', descending: true)
            .get();

        for (final recDoc in recordsSnapshot.docs) {
          results.add(MyRecord(
            recordId: recDoc.id,
            locationId: locDoc.id,
            locationName: locationName,
            data: recDoc.data(),
          ));
        }
      }

      // Sort all records by date descending
      results.sort((a, b) {
        final aDate = a.data['data'];
        final bDate = b.data['data'];
        if (aDate is Timestamp && bDate is Timestamp) {
          return bDate.compareTo(aDate);
        }
        return 0;
      });

      return results;
    } catch (e) {
      debugPrint('[NavSafety] Error fetching my records: $e');
      return [];
    }
  }

  /// Returns the total number of records across all locations.
  Future<int> getTotalRecordsCount() async {
    try {
      final locSnapshot = await _firestore
          .collection(_locationsCollection)
          .get();

      int total = 0;
      for (final locDoc in locSnapshot.docs) {
        final countSnapshot = await locDoc.reference
            .collection(_recordsSubcollection)
            .count()
            .get();
        total += countSnapshot.count ?? 0;
      }
      return total;
    } catch (e) {
      debugPrint('[NavSafety] Error counting records: $e');
      return 0;
    }
  }

  /// Updates an existing record.
  Future<void> updateRecord(
      String locationId, String recordId, Map<String, dynamic> data) async {
    await _firestore
        .collection(_locationsCollection)
        .doc(locationId)
        .collection(_recordsSubcollection)
        .doc(recordId)
        .update(data);
  }

  /// Deletes a record from a location's registros subcollection.
  Future<void> deleteRecord(String locationId, String recordId) async {
    await _firestore
        .collection(_locationsCollection)
        .doc(locationId)
        .collection(_recordsSubcollection)
        .doc(recordId)
        .delete();
  }
}

// =============================================================================
// DATA CLASSES
// =============================================================================

/// A record belonging to the current user, with location context.
class MyRecord {
  final String recordId;
  final String locationId;
  final String locationName;
  final Map<String, dynamic> data;

  MyRecord({
    required this.recordId,
    required this.locationId,
    required this.locationName,
    required this.data,
  });
}

/// A location with its most recent registro data.
class LocationWithLatestRecord {
  final String id;
  final String name;
  final Map<String, dynamic>? latestRecord;

  LocationWithLatestRecord({
    required this.id,
    required this.name,
    this.latestRecord,
  });

  String? get latestDepth {
    if (latestRecord == null) return null;
    final depth = latestRecord!['profundidadeTotal'];
    if (depth == null) return null;
    return depth.toString();
  }

  String? get latestDateFormatted {
    if (latestRecord == null) return null;
    final data = latestRecord!['data'];
    if (data is Timestamp) {
      final date = data.toDate();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    return null;
  }
}
