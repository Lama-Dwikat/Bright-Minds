import 'package:flutter/material.dart';
import 'package:bright_minds/theme/theme.dart';
import 'package:bright_minds/config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;




class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       body:Stack(
        children:[
          Image.asset(("assets/images/home2.png"), 
          fit:BoxFit.cover,
          width:double.infinity,
          height:double.infinity,
          ),
         
        ],
       ),

      
    );
  }
  
}