import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';

/// Handles active crossing data, cache invalidation, and user push preferences.
class CrossingController extends ChangeNotifier {
  static const Duration _cacheStaleThreshold = Duration(seconds: 30);

  static List<Map<String, dynamic>>? _cachedCrossings;
  static DateTime? _crossingsFetchTime;
  static List<Map<String, dynamic>>? _cachedMyCrossings;
  static DateTime? _myCrossingsFetchTime;
  static String? _cachedMyCrossingsUserId;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<Map<String, dynamic>> _crossings = [];
  List<Map<String, dynamic>> get crossings => _crossings;

  List<Map<String, dynamic>> _myCrossings = [];
  List<Map<String, dynamic>> get myCrossings => _myCrossings;

  Future<void> fetchActiveCrossings() async {
    if (_cachedCrossings != null && !_isCacheStale(_crossingsFetchTime)) {
      _crossings = _cachedCrossings!;
      _isLoading = false;
      _error = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final nowUtc = Timestamp.fromDate(DateTime.now().toUtc());
      final snapshot = await _firestore
          .collection(AppConstants.cruzamentosCollection)
          .where('dataHora', isGreaterThan: nowUtc)
          .orderBy('dataHora')
          .get();

      final all = snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();

      _cachedCrossings = all;
      _crossingsFetchTime = DateTime.now();
      _crossings = all;
    } catch (e) {
      debugPrint('[Crossing] Error fetching crossings: $e');
      _error = e.toString();
      _crossings = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyCrossings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _myCrossings = [];
      notifyListeners();
      return;
    }

    if (_cachedMyCrossings != null &&
        _cachedMyCrossingsUserId == uid &&
        !_isCacheStale(_myCrossingsFetchTime)) {
      _myCrossings = _cachedMyCrossings!;
      _isLoading = false;
      _error = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection(AppConstants.cruzamentosCollection)
          .where('pilotoId', isEqualTo: uid)
          .get();

      final all = snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();

      all.sort((a, b) {
        final aDate = _resolveDateTime(a['dataHora']);
        final bDate = _resolveDateTime(b['dataHora']);
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      _cachedMyCrossings = all;
      _cachedMyCrossingsUserId = uid;
      _myCrossingsFetchTime = DateTime.now();
      _myCrossings = all;
    } catch (e) {
      debugPrint('[Crossing] Error fetching my crossings: $e');
      _error = e.toString();
      _myCrossings = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> addCrossing(Map<String, dynamic> data) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final pilotCallSign = await _resolveCurrentUserCallSign();

    final payload = {
      ...data,
      'pilotoId': uid,
      'nomeGuerra': pilotCallSign,
      'createdAt': FieldValue.serverTimestamp(),
    };

    debugPrint('[Crossing] addCrossing -> keys=${payload.keys.toList()}');

    final docRef = await _firestore
        .collection(AppConstants.cruzamentosCollection)
        .add(payload);

    debugPrint('[Crossing] addCrossing OK -> docId=${docRef.id}');
    _invalidateCache();

    return {
      ...data,
      'id': docRef.id,
      'pilotoId': uid,
      'nomeGuerra': pilotCallSign,
    };
  }

  Future<void> deleteCrossing(String docId) async {
    debugPrint('[Crossing] deleteCrossing -> docId=$docId');

    await _firestore
        .collection(AppConstants.cruzamentosCollection)
        .doc(docId)
        .delete();

    debugPrint('[Crossing] deleteCrossing OK');
    _invalidateCache();
    notifyListeners();
  }

  Future<void> updateCrossing(
    String docId,
    Map<String, dynamic> data,
  ) async {
    debugPrint('[Crossing] updateCrossing -> docId=$docId');

    await _firestore
        .collection(AppConstants.cruzamentosCollection)
        .doc(docId)
        .update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    debugPrint('[Crossing] updateCrossing OK');
    _invalidateCache();
    notifyListeners();
  }

  Future<bool> isCrossingPushEnabled() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      final data = doc.data();
      if (data == null) return false;

      if (data.containsKey('pushCruzamento')) {
        final enabled = data['pushCruzamento'] as bool? ?? false;
        if (!enabled) return false;

        final expiry = _resolveDateTime(data['pushCruzamentoExpiry']);
        if (expiry != null && expiry.isBefore(DateTime.now().toUtc())) {
          return false;
        }

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('[Crossing] Error reading pushCruzamento: $e');
      return false;
    }
  }

  Future<DateTime?> getCrossingPushExpiryDate() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      return _resolveDateTime(doc.data()?['pushCruzamentoExpiry']);
    } catch (e) {
      debugPrint('[Crossing] Error reading pushCruzamentoExpiry: $e');
      return null;
    }
  }

  Future<void> setCrossingPushEnabled(
    bool enabled, {
    DateTime? expiryDate,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final payload = <String, dynamic>{
      'pushCruzamento': enabled,
    };

    if (enabled && expiryDate != null) {
      payload['pushCruzamentoExpiry'] = Timestamp.fromDate(
        expiryDate.toUtc(),
      );
    }

    if (!enabled) {
      payload['pushCruzamentoExpiry'] = FieldValue.delete();
    }

    await _firestore.collection(AppConstants.usersCollection).doc(uid).set(
      payload,
      SetOptions(merge: true),
    );
    debugPrint('[Crossing] setCrossingPushEnabled -> $enabled');
  }

  static void clearCache() {
    _cachedCrossings = null;
    _crossingsFetchTime = null;
    _cachedMyCrossings = null;
    _myCrossingsFetchTime = null;
    _cachedMyCrossingsUserId = null;
  }

  bool _isCacheStale(DateTime? fetchTime) {
    if (fetchTime == null) return true;
    return DateTime.now().difference(fetchTime) > _cacheStaleThreshold;
  }

  DateTime? _resolveDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    return null;
  }

  void _invalidateCache() {
    _cachedCrossings = null;
    _crossingsFetchTime = null;
    _cachedMyCrossings = null;
    _myCrossingsFetchTime = null;
    _cachedMyCrossingsUserId = null;
  }

  Future<String> _resolveCurrentUserCallSign() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return '';

    final authDisplayName = (currentUser.displayName ?? '').trim();

    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUser.uid)
          .get();
      final firestoreName =
          (userDoc.data()?['nomeGuerra'] ?? '').toString().trim();
      return firestoreName.isNotEmpty ? firestoreName : authDisplayName;
    } catch (_) {
      return authDisplayName;
    }
  }
}
