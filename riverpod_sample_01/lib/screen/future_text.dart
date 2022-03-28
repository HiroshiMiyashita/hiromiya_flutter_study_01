import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FutureText extends ConsumerStatefulWidget {
  const FutureText({Key? key}) : super(key: key);

  @override
  ConsumerState<FutureText> createState() => _FutureTextState();
}

class _FutureTextState extends ConsumerState<FutureText> {
  AutoDisposeFutureProvider<String>? _futureStringProvider;

  @override
  void initState() {
    super.initState();

    _futureStringProvider = AutoDisposeFutureProvider((ref) =>
        Future<String>.delayed(
            const Duration(seconds: 5), () => "After 5 second"));
  }

  @override
  Widget build(BuildContext context) {
    final futureStringProvider = _futureStringProvider;
    if (futureStringProvider == null) {
      return const Text("???");
    }
    final futureString = ref.watch(futureStringProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dog List'),
      ),
      body: Center(
        child: futureString.when(
          loading: () => const CircularProgressIndicator(),
          error: (err, stack) => Text("Error: $err"),
          data: (text) => Text(text),
        ),
      ),
    );
  }
}
