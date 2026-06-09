import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/game_state_controller.dart';
import 'screens/landing_screen.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  final gameController = GameStateController();
  runApp(MyApp(controller: gameController));
}

class MyApp extends StatelessWidget {
  final GameStateController controller;

  const MyApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'skribbl.io',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF133c64),
        scaffoldBackgroundColor: const Color(0xFF1c2630),
        textTheme: GoogleFonts.fredokaTextTheme(
          Theme.of(context).textTheme,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1e90ff),
          primary: const Color(0xFF1e90ff),
          secondary: const Color(0xFFffa500),
        ),
      ),
      home: LandingScreen(controller: controller),
    );
  }
}
