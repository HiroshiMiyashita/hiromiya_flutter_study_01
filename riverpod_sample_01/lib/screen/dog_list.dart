import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_sample_01/model/docs.dart';
import '../model/doc_filter.dart';
import '../data/providers.dart';

class DogListPage extends ConsumerStatefulWidget {
  const DogListPage({Key? key}) : super(key: key);

  @override
  ConsumerState<DogListPage> createState() => _DogListPageState();
}

class _DogListPageState extends ConsumerState<DogListPage> {
  AutoDisposeStateNotifierProvider<DocFilterNotifier, DocFilter>?
      _filterProvider;
  AutoDisposeStateNotifierProvider<DocsNotifier, List<DocumentSnapshot>>?
      _docsProvider;

  @override
  void initState() {
    super.initState();

    final filterProvider =
        StateNotifierProvider.autoDispose<DocFilterNotifier, DocFilter>(
      (ref) {
        return DocFilterNotifier((ds, [index, dss]) => true);
      },
    );
    _filterProvider = filterProvider;

    _docsProvider =
        StateNotifierProvider.autoDispose<DocsNotifier, List<DocumentSnapshot>>(
      (ref) {
        final srcDocs = ref.watch(dogDocsProvider);
        final filter = ref.watch(filterProvider);
        final docs = DocsNotifier();
        docs.setDocs(srcDocs.where((e) => filter(e)).toList());

        return docs;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filterProvider = _filterProvider;
    final docProvider = _docsProvider;
    if (filterProvider == null || docProvider == null) {
      return const Text("???");
    }
    final filter = ref.read(filterProvider.notifier);
    final docs = ref.watch(docProvider);

    final List<String> ids = docs.map((doc) => doc.id).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dog List'),
      ),
      body: Center(
        child: ListView.builder(
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final doc = docs[i];
            return InkWell(
              child: ListTile(
                title: Text(doc.get('name') as String),
                subtitle: Text("Votes: ${doc.get('votes') as int}"),
              ),
              onTap: () =>
                  doc.reference.update({"votes": FieldValue.increment(1)}),
            );
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              filter.setFilter((ds, [index, dss]) => true);
            },
            tooltip: 'All Data Show',
            heroTag: "All Data",
            child: const Text('Show All'),
          ),
          const Padding(padding: EdgeInsets.all(8)),
          FloatingActionButton(
            onPressed: () {
              filter.setFilter((ds, [index, dss]) => false);
            },
            tooltip: 'Hide Data Show',
            heroTag: "Hide Data",
            child: const Text('Hide All'),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
