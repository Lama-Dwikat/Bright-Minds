

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:bright_minds/widgets/navItem.dart';
import 'package:bright_minds/theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:bright_minds/screens/Signin.dart';
import 'package:bright_minds/screens/profilePage.dart';




class ProfilePage extends StatelessWidget {
  final String userId;
  const ProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Profile")),
      body: Center(child: Text("Profile of user: $userId")),
    );
  }
}
