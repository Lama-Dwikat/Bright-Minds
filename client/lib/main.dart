

import 'package:flutter/material.dart';
import 'package:bright_minds/screens/welcome.dart';




void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false , //to show  full page backgorund 
      title: "Bright Minds",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home:  WelcomeScreen(),
    );
  }
}

