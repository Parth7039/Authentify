import 'package:authent/Successpage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Import the options file
import 'package:flutter/material.dart';
import 'package:authent/authentication.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Use the correct options
  );
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthenticationPage(),
    );
  }
}
