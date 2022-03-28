import 'package:riverpod/riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class User extends StateNotifier<fb_auth.User?> {
  User() : super(null);

  void setUser(fb_auth.User? user) => state = user;
}
