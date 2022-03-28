import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

StreamController<DateTime> getDateTimeStreamController(Duration interval) {
  late StreamController<DateTime> controller;
  Timer? timer;

  void tick(Timer _timer) {
    controller.add(DateTime.now());
  }

  void startTimer() {
    timer = Timer.periodic(interval, tick);
  }

  void stopTimer() {
    timer?.cancel();
    timer = null;
  }

  controller = StreamController(
      onListen: startTimer,
      onPause: stopTimer,
      onResume: startTimer,
      onCancel: stopTimer);

  return controller;
}

class ClockPage extends ConsumerStatefulWidget {
  const ClockPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ClockPage> createState() => _ClockPageState();
}

class _ClockPageState extends ConsumerState<ClockPage> {
  final _dateTimeStreamController =
      getDateTimeStreamController(const Duration(milliseconds: 25));
  AutoDisposeStreamProvider<DateTime>? _dateTimeProvider;

  @override
  void initState() {
    super.initState();

    _dateTimeProvider = StreamProvider.autoDispose<DateTime>(
      (ref) async* {
        await for (final dt in _dateTimeStreamController.stream) {
          yield dt;
        }
      },
    );
  }

  @override
  void dispose() {
    _dateTimeStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateTimeProvider = _dateTimeProvider;
    if (dateTimeProvider == null) {
      return const Text("???");
    }
    final dateTime = ref.watch(dateTimeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dog List'),
      ),
      body: Center(
        child: dateTime.when(
          loading: () => const CircularProgressIndicator(),
          error: (err, stack) => Text("Error: $err"),
          data: (dt) => Text(dt.toIso8601String()),
        ),
      ),
    );
  }
}
