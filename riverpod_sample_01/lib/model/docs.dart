import 'package:riverpod/riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DocsNotifier extends StateNotifier<List<DocumentSnapshot>> {
  DocsNotifier() : super([]);

  void setDocs(List<DocumentSnapshot> docs) => state = docs;
}
