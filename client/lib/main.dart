

import 'package:flutter/material.dart';
import 'package:bright_minds/screens/welcome.dart';
import 'package:bright_minds/screens/home/homeSupervisor.dart';
import 'package:bright_minds/screens/games/gameSupervisor.dart';

import 'package:bright_minds/screens/videos/analytics.dart';
import 'package:bright_minds/screens/games/GuessWordTemplete.dart';

import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';




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
      home: WelcomeScreen(),

     


    );
  }
}

