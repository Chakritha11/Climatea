import 'package:flutter/material.dart';
import 'package:climatea/screens/loading_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Climatea',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B1020),
      ),
      home: const LoadingScreen(),
    );
  }
}