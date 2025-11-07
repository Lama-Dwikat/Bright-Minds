
import 'package:bright_minds/widgets/home.dart';
import 'package:flutter/material.dart';




class HomeParent extends StatelessWidget{
  const HomeParent({super.key});


@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Home'),
      ),
      body: const Center(
        child: Text(
          'Welcome, Parent!',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}