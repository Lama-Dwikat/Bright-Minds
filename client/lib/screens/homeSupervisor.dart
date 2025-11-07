
import 'package:bright_minds/widgets/home.dart';
import 'package:flutter/material.dart';




class HomeSupervisor extends StatelessWidget{
  const HomeSupervisor({super.key});


@override
  Widget build(BuildContext context) {
    return homePage(
      child: Column(
        children: [
          // Add your supervisor-specific widgets here
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 143, 25, 25),
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3), // changes position of shadow
                ),
              ],
            ),
            child: const Text(
              'Welcome, Supervisor!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9182FA),
              ),
            ),
          ),
          const SizedBox(height: 20),

            Container(  
              margin: const EdgeInsets.only(top: 20),
              child: const Text(
                'Here you can manage your team and monitor progress.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          


        ],
      ),

    );
  }
}