
import 'package:bright_minds/screens/supervisorKids.dart';
import 'package:bright_minds/screens/addVideo.dart';
import 'package:bright_minds/theme/colors.dart';
import 'package:bright_minds/widgets/home.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bright_minds/screens/tasksList.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:convert';

class KidDetails extends StatelessWidget{
    final Map kid;

  const KidDetails({super.key, required this.kid});
  //const KidDetails({super.key});
  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title:Text("kid detial")),
    body:Text("hello from kid detials "),
    );
  }
}


