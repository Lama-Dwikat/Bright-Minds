
import 'package:bright_minds/widgets/home.dart';
import 'package:flutter/material.dart';




class HomeAdmin extends StatelessWidget{
  const HomeAdmin({super.key});


@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Home'),
      ),
      body: const Center(
        child: Text(
          'Welcome, Admin!',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}