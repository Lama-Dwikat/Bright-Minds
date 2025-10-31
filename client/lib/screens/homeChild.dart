
import 'package:bright_minds/screens/homePage.dart';
import 'package:flutter/material.dart';




class HomeChild extends StatelessWidget{
  const HomeChild({super.key});


@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Child Home'),
      ),
      body: const Center(
        child: Text(
          'Welcome, Child!',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}