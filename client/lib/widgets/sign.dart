
import 'package:flutter/material.dart';
import 'package:bright_minds/theme/colors.dart';

class Sign extends StatelessWidget {
  const Sign({super.key, this.child});
  final Widget? child;
  

  @override
  Widget build(BuildContext context) {  
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
 
    return Scaffold(
     body:Stack(
  children:[
    Container(
 decoration: BoxDecoration(
    gradient: AppColors.buttonGradientGold  , // use the gradient here
    borderRadius: BorderRadius.circular(10),
  ),
        width: double.infinity,
      height: double.infinity,),
    Positioned(
      top: screenHeight * 0.05, // 5% from top     
       left:0,
      right:0,
     child: SizedBox(
      width: screenWidth * 0.5,  // 50% of screen width
      height: screenWidth * 0.5, // keep square shape
      child:Image.asset('assets/images/logo.png',fit:BoxFit.contain),
    )
    ),
    SafeArea(
     child: child! )
    ]
      ),
    
     
      );





  }
}
