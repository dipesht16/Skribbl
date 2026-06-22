import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'services/game_state_controller.dart';
import 'screens/landing_screen.dart';
import 'firebase_options.dart';

late final Future<void> firebaseInitFuture;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  // Disable runtime network fetches for Google Fonts to load fonts offline instantly
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize Firebase in the background so it doesn't block the first frame render
  firebaseInitFuture = Future(() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      debugPrint("Firebase initialization failed/already done: $e");
    }
  });

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
