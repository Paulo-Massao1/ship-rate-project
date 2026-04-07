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
  // CACHE (static — shared across all controller instances)
  // ===========================================================================

  /// Cached location docs (id + name only).
  static List<LocationWithLatestRecord>? _cachedLocationDocs;

  /// Cached locations with their latest record data (the full list view).
  static List<LocationWithLatestRecord>? _cachedLocationsWithLatest;

  /// Cached history per location id.
  static final Map<String, List<Map<String, dynamic>>> _cachedHistory = {};

  /// Cached "my records" for the current user.
  static List<MyRecord>? _cachedMyRecords;

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
  /// Serves from cache if available; only hits Firestore on first call
  /// or after explicit invalidation.
  Future<void> fetchLocationsWithLatestRecord() async {
    // Serve from cache instantly
    if (_cachedLocationsWithLatest != null) {
      _locations = _cachedLocationsWithLatest!;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Fetch location documents (or use cache)
      if (_cachedLocationDocs == null) {
        final snapshot = await _firestore
            .collection(_locationsCollection)
            .orderBy('nome')
            .get();

        _cachedLocationDocs = snapshot.docs
            .map((doc) => LocationWithLatestRecord(
                  id: doc.id,
                  name: (doc.data()['nome'] ?? '').toString(),
                ))
            .toList();
      }

      // Fetch latest record for each location in parallel
      final futures = _cachedLocationDocs!.map((loc) async {
        final latestSnapshot = await _firestore
            .collection(_locationsCollection)
            .doc(loc.id)
            .collection(_recordsSubcollection)
            .orderBy('data', descending: true)
            .limit(1)
            .get();

        Map<String, dynamic>? latestRecord;
        if (latestSnapshot.docs.isNotEmpty) {
          latestRecord = latestSnapshot.docs.first.data();
        }

        return LocationWithLatestRecord(
          id: loc.id,
          name: loc.name,
          latestRecord: latestRecord,
        );
      });

      _locations = await Future.wait(futures);
      _cachedLocationsWithLatest = _locations;
    } catch (e) {
      debugPrint('[NavSafety] Error fetching locations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches all registros for a specific location.
  /// Serves from cache if this location was already loaded.
  Future<void> fetchLocationHistory(String locationId, String locationName) async {
    _selectedLocationId = locationId;
    _selectedLocationName = locationName;

    // Serve from cache
    if (_cachedHistory.containsKey(locationId)) {
      _locationRecords = _cachedHistory[locationId]!;
      _isLoadingHistory = false;
      notifyListeners();
      return;
    }

    _isLoadingHistory = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection(_locationsCollection)
          .doc(locationId)
          .collection(_recordsSubcollection)
          .orderBy('data', descending: true)
          .get();

      _locationRecords = snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'recordId': doc.id,
              })
          .toList();
      _cachedHistory[locationId] = _locationRecords;
    } catch (e) {
      debugPrint('[NavSafety] Error fetching history: $e');
      _locationRecords = [];
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Creates a new location document and returns its ID.
  Future<String> addLocation(String name, {String? createdBy}) async {
    final payload = <String, dynamic>{
      'nome': name,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (createdBy != null && createdBy.isNotEmpty) {
      payload['createdBy'] = createdBy;
    }

    final doc = await _firestore.collection(_locationsCollection).add(payload);
    // Invalidate caches so new location appears
    _invalidateAllCaches();
    return doc.id;
  }

  /// Saves a new record to the registros subcollection of a location.
  Future<void> saveRecord(String locationId, Map<String, dynamic> data) async {
    await _firestore
        .collection(_locationsCollection)
        .doc(locationId)
        .collection(_recordsSubcollection)
        .add(data);
    _invalidateAllCaches();
  }

  /// Returns cached locations if available, otherwise fetches from Firestore.
  Future<List<LocationWithLatestRecord>> getCachedLocations() async {
    if (_cachedLocationDocs != null) return _cachedLocationDocs!;

    final snapshot = await _firestore
        .collection(_locationsCollection)
        .orderBy('nome')
        .get();

    _cachedLocationDocs = snapshot.docs
        .map((doc) => LocationWithLatestRecord(
              id: doc.id,
              name: (doc.data()['nome'] ?? '').toString(),
            ))
        .toList();

    return _cachedLocationDocs!;
  }

  /// Clears the selected location and returns to the list view.
  void clearSelection() {
    _selectedLocationId = null;
    _selectedLocationName = null;
    _locationRecords = [];
    notifyListeners();
  }

  /// Fetches all records belonging to the current user across all locations.
  /// Serves from cache if available.
  Future<List<MyRecord>> fetchMyRecords() async {
    if (_cachedMyRecords != null) return _cachedMyRecords!;

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

      _cachedMyRecords = results;
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
    _invalidateAllCaches();
  }

  /// Deletes a record from a location's registros subcollection.
  Future<void> deleteRecord(String locationId, String recordId) async {
    final locationRef =
        _firestore.collection(_locationsCollection).doc(locationId);

    await locationRef.collection(_recordsSubcollection).doc(recordId).delete();

    final locationSnapshot = await locationRef.get();
    final locationData = locationSnapshot.data();
    final remainingRecords =
        await locationRef.collection(_recordsSubcollection).limit(1).get();

    if ((locationData?['createdBy'] as String?)?.isNotEmpty == true &&
        remainingRecords.docs.isEmpty) {
      await locationRef.delete();
    }

    _invalidateAllCaches();
  }

  /// Invalidates all static caches, forcing a fresh fetch next time.
  static void _invalidateAllCaches() {
    _cachedLocationDocs = null;
    _cachedLocationsWithLatest = null;
    _cachedHistory.clear();
    _cachedMyRecords = null;
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

  String? get latestPilotName {
    if (latestRecord == null) return null;
    final name = latestRecord!['nomeGuerra'];
    if (name == null) return null;
    return name.toString();
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
