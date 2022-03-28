import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/docs.dart';

final dogDocsProvider =
    StateNotifierProvider<DocsNotifier, List<DocumentSnapshot>>(
  (ref) {
    final dogDocs = DocsNotifier();
    FirebaseFirestore.instance.collection('dogs').limit(10).snapshots().listen(
          (qss) => dogDocs.setDocs(qss.docs),
        );

    return dogDocs;
  },
);
