import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';
import 'homepage.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppLifecycleObserver(
      child: MaterialApp(
        title: 'Hedieaty',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: LoginPage(), // Always start with LoginPage
        routes: {
          '/login': (context) => LoginPage(),
          '/home': (context) => HomePage(),
        },
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text(
                '404 - Page not found!',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppLifecycleObserver extends StatefulWidget {
  final Widget child;

  AppLifecycleObserver({required this.child});

  @override
  _AppLifecycleObserverState createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver>
    with WidgetsBindingObserver {
  Timer? _signOutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _signOutTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Sign out after 10 minutes of inactivity
      _signOutTimer = Timer(Duration(minutes: 10), () {
        FirebaseAuth.instance.signOut();
      });
    } else if (state == AppLifecycleState.resumed) {
      // Cancel sign-out timer when the app resumes
      _signOutTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
