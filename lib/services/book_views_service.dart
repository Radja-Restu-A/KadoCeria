import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/book_views_model.dart';

class BookViewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _localStorageKey = 'book_views';

  Future<void> incrementBookViews(String bookId) async {
    await _incrementLocalViews(bookId);
    try{
      await _syncWithFirebase(bookId);
    } catch (e) {
      print ('Error syncing with Firebase: $e');
    }
  }

  Future<void> _incrementLocalViews(String bookId) async {
    final prefs =  await SharedPreferences.getInstance();
    final String? storedData = prefs.getString(_localStorageKey);

    Map<String, BookViews> viewsMap = {};
    if (storedData != null){
      final Map<String, dynamic> decoded = json.decode(storedData);
      viewsMap = decoded.map((key, value) =>
        MapEntry(key, BookViews.fromJson(value as Map<String, dynamic>))
      );
    }

    if (viewsMap.containsKey(bookId)){
      viewsMap[bookId]!.views++;
      viewsMap[bookId]!.lastUpdated = DateTime.now();
    } else {
      viewsMap[bookId] = BookViews(bookId: bookId, views: 1);
    }

    await prefs.setString(_localStorageKey,jsonEncode(viewsMap.map((key,value) => MapEntry(key, value.toJson()))));
  }

  Future<void> _syncWithFirebase(String bookId) async{
    final prefs = await SharedPreferences.getInstance();
    final String? storedData = prefs.getString(_localStorageKey);

    if (storedData == null) return;

    final Map<String, dynamic> decoded = json.decode(storedData);
    final Map<String, BookViews> viewsMap = decoded.map((key, value) => MapEntry(key, BookViews.fromJson(value as Map<String, dynamic>)));

    if (!viewsMap.containsKey(bookId)) return;

    final BookViews localViews = viewsMap[bookId]!;

    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('book_views').doc(bookId);
      final snapshot = await transaction.get(docRef);

      if(!snapshot.exists){
        transaction.set(docRef, {
          'views': localViews.views,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }else{
        transaction.update(docRef, {
          'views': FieldValue.increment(localViews.views),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    });

    viewsMap.remove(bookId);
    await prefs.setString(_localStorageKey, json.encode(viewsMap.map((key, value) => MapEntry(key, value.toJson()))));
  }

  Future<int> getBookViews(String bookId) async {
    try{
      final doc = await _firestore.collection('book_views').doc(bookId).get();
      return doc.exists ? (doc.data()?['views'] ?? 0) : 0;
    } catch (e) {
      print('failed to get book views from Firebase: $e');
      return 0;
    }
  }
}