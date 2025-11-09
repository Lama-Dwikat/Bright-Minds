import 'package:bright_minds/screens/supervisorKids.dart';
import 'package:bright_minds/widgets/home.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:jwt_decoder/jwt_decoder.dart';


  class SupervisorVideosScreen extends StatefulWidget {
    const SupervisorVideosScreen({super.key});

    @override
    State<SupervisorVideosScreen> createState() =>_SupervisorVidoesState();

  }

  class _SupervisorVidoesState extends State<SupervisorVideosScreen> {
    @override
    Widget build (BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Supervisor Videos'),
        ),
        body: Center(
          child: Text('Videos for Supervisor'),
        ),
      );
    }
  }
