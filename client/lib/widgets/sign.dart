
import 'package:flutter/material.dart';

class Sign extends StatelessWidget {
  const Sign({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {   
    return Scaffold(
     body:Stack(
  children:[
    Container(
color: const Color.fromARGB(255, 149, 138, 252),     
      width: double.infinity,
      height: double.infinity,),
    Positioned(
      top:30,
      left:0,
      right:0,
     child: SizedBox(
      width:250,
      height:250,
      child:Image.asset('assets/images/image2.png',fit:BoxFit.contain),
    )
    ),
    SafeArea(
     child: child! )
    ]
      ),
    
     
      );





  }
}
