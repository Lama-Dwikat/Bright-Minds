
import 'package:bright_minds/screens/homePage.dart';
import 'package:flutter/material.dart';




class HomeSupervisor extends StatelessWidget{
  const HomeSupervisor({super.key});


@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisor Home'),
      ),
      body: const Center(
        child: Text(
          'Welcome, Supervisor!',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}