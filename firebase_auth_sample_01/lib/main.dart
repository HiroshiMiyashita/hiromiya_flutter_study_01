import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:flutterfire_ui/i10n.dart';
import 'package:firebase_auth_sample_01/signin_localization_ja.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        FlutterFireUILocalizations.withDefaultOverrides(
            FlutterFireUIJaLocalizationLabels()),

        // Delegates below take care of built-in flutter widgets
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,

        // This delegate is required to provide the labels that are not overridden by LabelOverrides
        FlutterFireUILocalizations.delegate,
      ],
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return const Scaffold(body: CustomEmailSignInForm());
          // return SignInScreen(
          //   providerConfigs: const [EmailProviderConfiguration()],
          //   headerBuilder: (context, constrains, shrinkOffset) =>
          //       Image.asset("assets/images/sample.png"),
          // );
        }

        if (user.emailVerified) {
          return const MyHomePage(title: 'Flutter Demo Home Page');
        }

        user.sendEmailVerification();
        return ReloadForEmailVerification(user.email ?? "");
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CustomEmailSignInForm extends StatefulWidget {
  const CustomEmailSignInForm({Key? key}) : super(key: key);

  @override
  State<CustomEmailSignInForm> createState() => _CustomEmailSignInFormState();
}

class _CustomEmailSignInFormState extends State<CustomEmailSignInForm> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFlowBuilder<EmailFlowController>(
      builder: (context, state, ctrl, child) {
        if (state is AwaitingEmailAndPassword) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/sample.png'),
                const EmailForm(action: AuthAction.signIn),
              ],
            ),
          );
          // return Column(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     TextField(
          //       controller: emailCtrl,
          //     ),
          //     TextField(
          //       controller: passwordCtrl,
          //     ),
          //     ElevatedButton(
          //       onPressed: () {
          //         ctrl.setEmailAndPassword(emailCtrl.text, passwordCtrl.text);
          //       },
          //       child: const Text("Sign in"),
          //     ),
          //   ],
          // );
        } else if (state is SigningIn) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is AuthFailed) {
          return ErrorText(exception: state.exception);
        }

        return const Text("");
      },
    );
  }
}

class ReloadForEmailVerification extends StatelessWidget {
  final String email;

  const ReloadForEmailVerification(this.email, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("$emailに確認用メールを送信しました."),
            const Padding(padding: EdgeInsets.all(10)),
            ElevatedButton(
              child: const Text("確認が終わったらクリック"),
              onPressed: () {
                FirebaseAuth.instance.currentUser?.reload();
              },
            ),
          ],
        ),
      ),
    );
  }
}
