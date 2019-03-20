import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'gem.dart';

final CollectionReference postsCollection = Firestore.instance.collection('posts');
class FirebaseFirestoreService {

  static final FirebaseFirestoreService _instance = new FirebaseFirestoreService
      .internal();

  factory FirebaseFirestoreService() => _instance;

  FirebaseFirestoreService.internal();

  Future<Gem> createGem(String name, String description, List <String> tags, String gps, String userid, String picture, bool finished, List <int> rating) async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      final DocumentSnapshot ds = await tx.get(postsCollection.document());

      final Gem gem = new Gem(ds.documentID, name, description, tags, gps, userid, picture, finished, rating);
      final Map<String, dynamic> data = gem.toMap();

      await tx.set(ds.reference, data);

      return data;
    };

    return Firestore.instance.runTransaction(createTransaction).then((mapData) {
      return Gem.fromMap(mapData);
    }).catchError((error) {
      print('error: $error');
      return null;
    });
  }
}