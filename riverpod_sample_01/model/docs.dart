import 'package:riverpod/riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDocsNotifier extends StateNotifier<QuerySnapshot?> {
  UserDocsNotifier(User? user) : super(null) {
    state = null;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users/${user.uid}/docs')
          .limit(10)
          .snapshots()
          .listen((docs) => state = docs);
    }
  }
}
