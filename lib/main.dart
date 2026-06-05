import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const AirHockeyApp());
}

class AirHockeyApp extends StatelessWidget {
  const AirHockeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Air Hockey',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.pinkAccent,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
