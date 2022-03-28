import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_sample_01/screen/clock.dart';
import 'package:riverpod_sample_01/screen/future_text.dart';
import './screen/dog_list.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHome(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHome extends StatelessWidget {
  final String title;

  const MyHome({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Open Dog List Page'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const DogListPage()),
              ),
            ),
            const Text("(StateNotificationProvider Sample)"),
            const Padding(padding: EdgeInsets.all(8)),
            ElevatedButton(
              child: const Text('Open Clock Page'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const ClockPage()),
              ),
            ),
            const Text("(StreamProviderSample)"),
            const Padding(padding: EdgeInsets.all(8)),
            ElevatedButton(
              child: const Text('Open Future Text Page'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const FutureText()),
              ),
            ),
            const Text("(FutureProviderSample)"),
          ],
        ),
      ),
    );
  }
}
