import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'dart:async';

import '../models/book_views_model.dart';

class BookViewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _localStorageKey = 'book_views';
  final String _syncedViewsKey = 'synced_views';
  final String _lastKnownViewsKey = 'last_known_views'; 
  final Connectivity _connectivity = Connectivity();

  bool _isOnline = true;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isInitialized = false;

  Future<void> _initializeConnectivity() async {
    if (_isInitialized) return;

    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) async {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;

      print('Connectivity changed: ${_isOnline ? "Online" : "Offline"}');

      if (wasOffline && _isOnline) {
        await _syncAllPendingViews();
      }
    });

    _isInitialized = true;
  }

  Future<void> incrementBookViews(String bookId) async {
    await _initializeConnectivity();

    await _incrementLocalViews(bookId);

    if (_isOnline) {
      try {
        await _syncWithFirebase(bookId);
        print('Successfully synced view for $bookId');
      } catch (e) {
        print('Error syncing with Firebase: $e');
      }
    } else {
      print('Offline: View for $bookId will be synced when back online');
    }
  }

  Future<void> _incrementLocalViews(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedData = prefs.getString(_localStorageKey);

    Map<String, BookViews> viewsMap = {};
    if (storedData != null) {
      final Map<String, dynamic> decoded = json.decode(storedData);
      viewsMap = decoded.map((key, value) =>
          MapEntry(key, BookViews.fromJson(value as Map<String, dynamic>))
      );
    }

    if (viewsMap.containsKey(bookId)) {
      viewsMap[bookId]!.views++;
      viewsMap[bookId]!.lastUpdated = DateTime.now();
    } else {
      viewsMap[bookId] = BookViews(bookId: bookId, views: 1);
    }

    await prefs.setString(_localStorageKey,
        json.encode(viewsMap.map((key, value) => MapEntry(key, value.toJson()))));

    final currentTotal = await _getCurrentTotalViews(bookId);
    await _updateLastKnownViews(bookId, currentTotal);
  }

  Future<int> _getCurrentTotalViews(String bookId) async {
    int total = 0;

    final prefs = await SharedPreferences.getInstance();
    final String? storedData = prefs.getString(_localStorageKey);

    if (storedData != null) {
      final Map<String, dynamic> decoded = json.decode(storedData);
      if (decoded.containsKey(bookId)) {
        final localViews = BookViews.fromJson(decoded[bookId]);
        total = localViews.views;
      }
    }

    return total;
  }

  Future<void> _updateLastKnownViews(String bookId, int totalViews) async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastKnownData = prefs.getString(_lastKnownViewsKey);

    Map<String, int> lastKnownMap = {};
    if (lastKnownData != null) {
      lastKnownMap = Map<String, int>.from(json.decode(lastKnownData));
    }

    lastKnownMap[bookId] = totalViews;
    await prefs.setString(_lastKnownViewsKey, json.encode(lastKnownMap));
    print('Updated last known views for $bookId: $totalViews');
  }

  Future<int> _getLastKnownViews(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastKnownData = prefs.getString(_lastKnownViewsKey);

    if (lastKnownData != null) {
      final Map<String, int> lastKnownMap = Map<String, int>.from(json.decode(lastKnownData));
      return lastKnownMap[bookId] ?? 0;
    }

    return 0;
  }

  Future<void> _syncWithFirebase(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedData = prefs.getString(_localStorageKey);

    if (storedData == null) return;

    final Map<String, dynamic> decoded = json.decode(storedData);
    final Map<String, BookViews> viewsMap = decoded.map((key, value) =>
        MapEntry(key, BookViews.fromJson(value as Map<String, dynamic>)));

    if (!viewsMap.containsKey(bookId)) return;

    final BookViews localViews = viewsMap[bookId]!;

    final syncedViews = await _getSyncedViews(bookId);
    final viewsToSync = localViews.views - syncedViews;

    if (viewsToSync <= 0) return;

    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection('book_views').doc(bookId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          transaction.set(docRef, {
            'views': viewsToSync,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(docRef, {
            'views': FieldValue.increment(viewsToSync),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });

      await _markViewsAsSynced(bookId, localViews.views);

      final updatedFirebaseViews = await _getFirebaseViews(bookId);
      if (updatedFirebaseViews > 0) {
        await _updateLastKnownViews(bookId, updatedFirebaseViews);
      }

      print('Successfully synced $viewsToSync views for $bookId');

    } catch (e) {
      print('Error syncing to Firebase: $e');
      throw e;
    }
  }

  Future<int> _getFirebaseViews(String bookId) async {
    try {
      final doc = await _firestore.collection('book_views').doc(bookId).get();
      return doc.exists ? (doc.data()?['views'] ?? 0) : 0;
    } catch (e) {
      print('Error fetching Firebase views: $e');
      return 0;
    }
  }

  Future<int> _getSyncedViews(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? syncedData = prefs.getString(_syncedViewsKey);

    if (syncedData == null) return 0;

    final Map<String, dynamic> syncedMap = json.decode(syncedData);
    return syncedMap[bookId] ?? 0;
  }

  Future<void> _markViewsAsSynced(String bookId, int totalSyncedViews) async {
    final prefs = await SharedPreferences.getInstance();
    final String? syncedData = prefs.getString(_syncedViewsKey);

    Map<String, dynamic> syncedMap = {};
    if (syncedData != null) {
      syncedMap = json.decode(syncedData);
    }

    syncedMap[bookId] = totalSyncedViews;
    await prefs.setString(_syncedViewsKey, json.encode(syncedMap));
  }

  Future<void> _syncAllPendingViews() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedData = prefs.getString(_localStorageKey);

    if (storedData == null) return;

    try {
      final Map<String, dynamic> decoded = json.decode(storedData);
      final Map<String, BookViews> viewsMap = decoded.map((key, value) =>
          MapEntry(key, BookViews.fromJson(value as Map<String, dynamic>)));

      print('Syncing ${viewsMap.length} books with pending views');

      for (final bookId in viewsMap.keys) {
        try {
          await _syncWithFirebase(bookId);
        } catch (e) {
          print('Failed to sync views for $bookId: $e');
        }
      }

      print('Finished syncing all pending views');
    } catch (e) {
      print('Error syncing all pending views: $e');
    }
  }

  Future<int> getBookViews(String bookId) async {
    await _initializeConnectivity();

    try {
      if (_isOnline) {
        int firebaseViews = 0;
        int localPendingViews = 0;

        final doc = await _firestore.collection('book_views').doc(bookId).get();
        firebaseViews = doc.exists ? (doc.data()?['views'] ?? 0) : 0;

        final prefs = await SharedPreferences.getInstance();
        final String? storedData = prefs.getString(_localStorageKey);

        if (storedData != null) {
          final Map<String, dynamic> decoded = json.decode(storedData);
          if (decoded.containsKey(bookId)) {
            final localViews = BookViews.fromJson(decoded[bookId]);
            final syncedViews = await _getSyncedViews(bookId);
            localPendingViews = localViews.views - syncedViews;
          }
        }

        final totalViews = firebaseViews + (localPendingViews > 0 ? localPendingViews : 0);

        await _updateLastKnownViews(bookId, totalViews);

        print('getBookViews($bookId): ONLINE - Firebase=$firebaseViews, LocalPending=$localPendingViews, Total=$totalViews');
        return totalViews;

      } else {
        print('OFFLINE: Getting views for $bookId from local storage');

        final lastKnownViews = await _getLastKnownViews(bookId);
        int additionalLocalViews = 0;

        final prefs = await SharedPreferences.getInstance();
        final String? storedData = prefs.getString(_localStorageKey);

        if (storedData != null) {
          final Map<String, dynamic> decoded = json.decode(storedData);
          if (decoded.containsKey(bookId)) {
            final localViews = BookViews.fromJson(decoded[bookId]);
            final syncedViews = await _getSyncedViews(bookId);

            additionalLocalViews = localViews.views - syncedViews;
            if (additionalLocalViews < 0) additionalLocalViews = 0;
          }
        }

        final offlineTotal = lastKnownViews + additionalLocalViews;
        print('getBookViews($bookId): OFFLINE - LastKnown=$lastKnownViews, Additional=$additionalLocalViews, Total=$offlineTotal');

        return offlineTotal;
      }

    } catch (e) {
      print('Failed to get book views: $e');

      final lastKnownViews = await _getLastKnownViews(bookId);

      if (lastKnownViews > 0) {
        print('Using last known views for $bookId: $lastKnownViews');
        return lastKnownViews;
      }

      final prefs = await SharedPreferences.getInstance();
      final String? storedData = prefs.getString(_localStorageKey);

      if (storedData != null) {
        final Map<String, dynamic> decoded = json.decode(storedData);
        if (decoded.containsKey(bookId)) {
          final localViews = BookViews.fromJson(decoded[bookId]);
          print('Final fallback - using local views for $bookId: ${localViews.views}');
          return localViews.views;
        }
      }

      return 0;
    }
  }

  Future<void> forceSyncAll() async {
    if (_isOnline) {
      await _syncAllPendingViews();
    } else {
      print('Cannot sync: Device is offline');
    }
  }

  Future<bool> hasPendingViews() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedData = prefs.getString(_localStorageKey);

    if (storedData == null) return false;

    try {
      final Map<String, dynamic> decoded = json.decode(storedData);

      for (final entry in decoded.entries) {
        final bookId = entry.key;
        final localViews = BookViews.fromJson(entry.value);
        final syncedViews = await _getSyncedViews(bookId);

        if (localViews.views > syncedViews) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking pending views: $e');
      return false;
    }
  }

  bool get isOnline => _isOnline;

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}