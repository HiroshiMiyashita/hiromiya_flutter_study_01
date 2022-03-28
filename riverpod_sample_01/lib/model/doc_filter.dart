import 'package:riverpod/riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

typedef DocFilter = bool Function(DocumentSnapshot ds,
    [int? index, List<DocumentSnapshot>? dss]);

class DocFilterNotifier extends StateNotifier<DocFilter> {
  DocFilterNotifier(DocFilter filter) : super(filter);

  void setFilter(DocFilter filter) => state = filter;
}
