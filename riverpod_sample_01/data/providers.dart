import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/login_user.dart';
import '../model/user_docs.dart';

final users = StreamProvider<User?>(
  (ref) async* {
    Stream<User?> users = FirebaseAuth.instance.userChanges();

    await for (final user in users) {
      yield user;
    }
  },
);

final loginUserProvider =
    StateNotifierProvider<LoginUserNotifier, User?>((ref) {
  final loginUser = LoginUserNotifier();

  return loginUser;
});

final prefProvider = StateNotifierProvider<UserDocsNotifier, QuerySnapshot?>(
  (ref) {
    final user = ref.watch(loginUserProvider);
    final userDocs = UserDocsNotifier(user);

    return userDocs;
  },
);
