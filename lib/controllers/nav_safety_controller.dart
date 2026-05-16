import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/services/image_upload_service.dart';

/// Controller for the Navigation Safety module.
///
/// Manages location data, record history, and user records with
/// in-memory caching and staleness checks to minimize Firestore reads.
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
  static const Duration _cacheStaleThreshold = Duration(seconds: 30);

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

  /// Cached total records count.
  static int? _cachedTotalRecordsCount;

  /// Cached like states: { "locationId/recordId": true/false }
  static final Map<String, bool> _cachedLikeStates = {};

  /// Cached like counts: { "locationId/recordId": count }
  static final Map<String, int> _cachedLikeCounts = {};

  /// Cached likers: { "locationId/recordId": [names...] }
  static final Map<String, List<String>> _cachedLikerNames = {};

  /// Timestamps for staleness checks.
  static DateTime? _locationsWithLatestFetchTime;
  static DateTime? _myRecordsFetchTime;
  static DateTime? _totalCountFetchTime;
  static final Map<String, DateTime> _historyFetchTimes = {};

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
  /// Serves from cache if available and not stale.
  Future<void> fetchLocationsWithLatestRecord() async {
    if (_cachedLocationsWithLatest != null && !_isCacheStale(_locationsWithLatestFetchTime)) {
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

      _locations.sort((a, b) {
        final aTs = a.latestRecord?['data'] as Timestamp?;
        final bTs = b.latestRecord?['data'] as Timestamp?;
        if (aTs != null && bTs != null) return bTs.compareTo(aTs);
        if (aTs != null) return -1;
        if (bTs != null) return 1;
        return a.name.compareTo(b.name);
      });

      _cachedLocationsWithLatest = _locations;
      _locationsWithLatestFetchTime = DateTime.now();
    } catch (e) {
      debugPrint('[NavSafety] Error fetching locations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches all registros for a specific location.
  /// Serves from cache if available and not stale.
  Future<void> fetchLocationHistory(String locationId, String locationName) async {
    _selectedLocationId = locationId;
    _selectedLocationName = locationName;

    if (_cachedHistory.containsKey(locationId) &&
        !_isCacheStale(_historyFetchTimes[locationId])) {
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
      _historyFetchTimes[locationId] = DateTime.now();
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
    debugPrint('[NavSafety] addLocation → name=$name, createdBy=$createdBy');
    final payload = <String, dynamic>{
      'nome': name,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (createdBy != null && createdBy.isNotEmpty) {
      payload['createdBy'] = createdBy;
    }

    final doc = await _firestore.collection(_locationsCollection).add(payload);
    debugPrint('[NavSafety] addLocation OK → docId=${doc.id}');
    _invalidateAllCaches();
    return doc.id;
  }

  /// Deletes a location if it belongs to the current user and has no records.
  Future<void> deleteLocationIfEmpty(String locationId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final locationRef = _firestore.collection(_locationsCollection).doc(locationId);
    final snapshot = await locationRef.get();
    final data = snapshot.data();
    if (data == null) return;

    final createdBy = (data['createdBy'] ?? '').toString();
    if (createdBy != uid) return;

    final remainingRecords =
        await locationRef.collection(_recordsSubcollection).limit(1).get();
    if (remainingRecords.docs.isNotEmpty) return;

    await locationRef.delete();
    debugPrint('[NavSafety] deleteLocationIfEmpty -> location deleted id=$locationId');
    _invalidateAllCaches();
  }

  /// Saves a new record to the registros subcollection of a location.
  Future<void> saveRecord(String locationId, Map<String, dynamic> data) async {
    debugPrint('[NavSafety] saveRecord → locationId=$locationId, keys=${data.keys.toList()}');
    try {
      final docRef = await _firestore
          .collection(_locationsCollection)
          .doc(locationId)
          .collection(_recordsSubcollection)
          .add(data);
      debugPrint('[NavSafety] saveRecord OK → docId=${docRef.id}');
      _invalidateAllCaches();
    } catch (e) {
      debugPrint('[NavSafety] saveRecord FAILED → $e');
      rethrow;
    }
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

  // ===========================================================================
  // LIKE METHODS
  // ===========================================================================

  String _likeKey(String locationId, String recordId) =>
      '$locationId/$recordId';

  Future<void> toggleLike(String locationId, String recordId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final key = _likeKey(locationId, recordId);
    final likeRef = _firestore
        .collection(_locationsCollection)
        .doc(locationId)
        .collection(_recordsSubcollection)
        .doc(recordId)
        .collection('likes')
        .doc(uid);

    final liked = _cachedLikeStates[key] ?? false;

    if (liked) {
      _cachedLikeStates[key] = false;
      _cachedLikeCounts[key] = ((_cachedLikeCounts[key] ?? 1) - 1).clamp(0, 999999);
      final currentUser = FirebaseAuth.instance.currentUser;
      final userName = currentUser?.displayName ?? '';
      _cachedLikerNames[key]?.remove(userName);
      notifyListeners();

      try {
        await likeRef.delete();
      } catch (e) {
        _cachedLikeStates[key] = true;
        _cachedLikeCounts[key] = (_cachedLikeCounts[key] ?? 0) + 1;
        if (userName.isNotEmpty) {
          _cachedLikerNames[key] ??= [];
          _cachedLikerNames[key]!.add(userName);
        }
        notifyListeners();
        debugPrint('[NavSafety] Error removing like: $e');
      }
    } else {
      final currentUser = FirebaseAuth.instance.currentUser;
      final nomeGuerra = currentUser?.displayName ?? '';

      _cachedLikeStates[key] = true;
      _cachedLikeCounts[key] = (_cachedLikeCounts[key] ?? 0) + 1;
      if (nomeGuerra.isNotEmpty) {
        _cachedLikerNames[key] ??= [];
        _cachedLikerNames[key]!.add(nomeGuerra);
      }
      notifyListeners();

      try {
        await likeRef.set({
          'nomeGuerra': nomeGuerra,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        _cachedLikeStates[key] = false;
        _cachedLikeCounts[key] = ((_cachedLikeCounts[key] ?? 1) - 1).clamp(0, 999999);
        _cachedLikerNames[key]?.remove(nomeGuerra);
        notifyListeners();
        debugPrint('[NavSafety] Error adding like: $e');
      }
    }
  }

  bool hasUserLiked(String locationId, String recordId) {
    return _cachedLikeStates[_likeKey(locationId, recordId)] ?? false;
  }

  int getLikeCount(String locationId, String recordId) {
    return _cachedLikeCounts[_likeKey(locationId, recordId)] ?? 0;
  }

  List<String> getLikerNames(String locationId, String recordId) {
    return _cachedLikerNames[_likeKey(locationId, recordId)] ?? [];
  }

  Future<List<String>> fetchAllLikerNames(
    String locationId,
    String recordId,
  ) async {
    final likesSnapshot = await _firestore
        .collection(_locationsCollection)
        .doc(locationId)
        .collection(_recordsSubcollection)
        .doc(recordId)
        .collection('likes')
        .orderBy('timestamp', descending: true)
        .get();

    return likesSnapshot.docs
        .map((doc) => (doc.data()['nomeGuerra'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  Future<void> loadLikeStatesForRecords(
      String locationId, List<Map<String, dynamic>> records) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final futures = records.map((record) async {
      final recordId = record['recordId'] as String?;
      if (recordId == null) return;

      final key = _likeKey(locationId, recordId);
      if (_cachedLikeStates.containsKey(key)) return;

      final likesRef = _firestore
          .collection(_locationsCollection)
          .doc(locationId)
          .collection(_recordsSubcollection)
          .doc(recordId)
          .collection('likes');

      final userLikeDoc = await likesRef.doc(uid).get();
      _cachedLikeStates[key] = userLikeDoc.exists;

      _cachedLikeCounts[key] = record['likeCount'] as int? ?? 0;

      final likesSnapshot =
          await likesRef.orderBy('timestamp', descending: true).limit(5).get();
      _cachedLikerNames[key] = likesSnapshot.docs
          .map((doc) => (doc.data()['nomeGuerra'] ?? '').toString())
          .where((name) => name.isNotEmpty)
          .toList();
    });

    await Future.wait(futures);
    notifyListeners();
  }

  /// Clears the selected location and returns to the list view.
  void clearSelection() {
    _selectedLocationId = null;
    _selectedLocationName = null;
    _locationRecords = [];
    notifyListeners();
  }

  /// Fetches all records belonging to the current user across all locations
  /// using a collection group query for performance.
  /// Serves from cache if available and not stale.
  Future<List<MyRecord>> fetchMyRecords() async {
    if (_cachedMyRecords != null && !_isCacheStale(_myRecordsFetchTime)) {
      return _cachedMyRecords!;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return [];

    try {
      // Single collection group query instead of N+1 queries
      final recordsSnapshot = await _firestore
          .collectionGroup(_recordsSubcollection)
          .where('pilotId', isEqualTo: uid)
          .orderBy('data', descending: true)
          .get();

      // Build a location name lookup from cache or fetch
      final locationDocs = await getCachedLocations();
      final locationNameMap = {
        for (final loc in locationDocs) loc.id: loc.name,
      };

      final results = <MyRecord>[];
      for (final recDoc in recordsSnapshot.docs) {
        // Path: locais/{locationId}/registros/{recordId}
        final locationId = recDoc.reference.parent.parent!.id;
        final locationName = locationNameMap[locationId] ?? '';

        results.add(MyRecord(
          recordId: recDoc.id,
          locationId: locationId,
          locationName: locationName,
          data: recDoc.data(),
        ));
      }

      _cachedMyRecords = results;
      _myRecordsFetchTime = DateTime.now();
      return results;
    } catch (e) {
      debugPrint('[NavSafety] Error fetching my records: $e');
      return [];
    }
  }

  /// Returns the total number of records across all locations
  /// using a collection group query.
  Future<int> getTotalRecordsCount() async {
    if (_cachedTotalRecordsCount != null && !_isCacheStale(_totalCountFetchTime)) {
      return _cachedTotalRecordsCount!;
    }

    try {
      final countSnapshot = await _firestore
          .collectionGroup(_recordsSubcollection)
          .count()
          .get();
      _cachedTotalRecordsCount = countSnapshot.count ?? 0;
      _totalCountFetchTime = DateTime.now();
      return _cachedTotalRecordsCount!;
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
  /// If the location was user-created and has no remaining records, deletes the location too.
  Future<void> deleteRecord(String locationId, String recordId) async {
    debugPrint('[NavSafety] deleteRecord → locationId=$locationId, recordId=$recordId');
    final locationRef =
        _firestore.collection(_locationsCollection).doc(locationId);

    final recordDoc = await locationRef.collection(_recordsSubcollection).doc(recordId).get();
    final imageUrls = List<String>.from(recordDoc.data()?['imageUrls'] ?? []);

    await locationRef.collection(_recordsSubcollection).doc(recordId).delete();
    debugPrint('[NavSafety] deleteRecord → record deleted from Firestore');

    if (imageUrls.isNotEmpty) {
      try {
        await ImageUploadService.deleteImages(imageUrls);
        debugPrint('[NavSafety] deleteRecord → ${imageUrls.length} images deleted from Storage');
      } catch (e) {
        debugPrint('[NavSafety] deleteRecord → image cleanup failed: $e');
      }
    }

    final locationSnapshot = await locationRef.get();
    final locationData = locationSnapshot.data();
    final remainingRecords =
        await locationRef.collection(_recordsSubcollection).limit(1).get();

    if ((locationData?['createdBy'] as String?)?.isNotEmpty == true &&
        remainingRecords.docs.isEmpty) {
      await locationRef.delete();
      debugPrint('[NavSafety] deleteRecord → orphan location deleted');
    }

    _invalidateAllCaches();
  }

  // ===========================================================================
  // PRIVATE METHODS
  // ===========================================================================

  /// Returns true if the cache is stale or has never been fetched.
  bool _isCacheStale(DateTime? fetchTime) {
    if (fetchTime == null) return true;
    return DateTime.now().difference(fetchTime) > _cacheStaleThreshold;
  }

  /// Clears all static cached data. Call on logout to prevent cross-session leaks.
  static void clearAllCaches() {
    _invalidateAllCaches();
  }

  /// Invalidates all static caches, forcing a fresh fetch next time.
  static void _invalidateAllCaches() {
    _cachedLocationDocs = null;
    _cachedLocationsWithLatest = null;
    _cachedHistory.clear();
    _cachedMyRecords = null;
    _cachedTotalRecordsCount = null;
    _cachedLikeStates.clear();
    _cachedLikeCounts.clear();
    _cachedLikerNames.clear();
    _locationsWithLatestFetchTime = null;
    _myRecordsFetchTime = null;
    _totalCountFetchTime = null;
    _historyFetchTimes.clear();
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
