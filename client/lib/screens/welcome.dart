

import 'package:flutter/material.dart';
import 'package:bright_minds/screens/signin.dart';
import 'package:bright_minds/screens/signup.dart';
import 'package:flutter/gestures.dart';//to use TapGestureRecognizer for clickable text
import 'package:bright_minds/theme/colors.dart';


class WelcomeScreen extends StatelessWidget {
  WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
  final Size screenSize=MediaQuery.of(context).size;
  final double screenHeight=screenSize.height;
  final double screenWidth=screenSize.width;

   return  Scaffold(
      body:Stack(
        children:[
          Image.asset(("assets/images/welcome.png"), 
          fit:BoxFit.cover,
          width:screenWidth,
          height:screenHeight,
          ),
               Positioned(
              bottom: screenHeight * 0.22, // 25% from bottom
              left: screenWidth * 0.51 ,
           child:   Container(
              width: screenWidth * 0.43, // 40% of screen width
              height: screenHeight * 0.07, // 8% of screen height
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color:Colors.white,
                ),
           child: MaterialButton(onPressed: (){
            Navigator.push(context,MaterialPageRoute(builder:(context)=>SignInScreen()));
           },
           textColor: AppColors.bgSoftPinkVeryDark,
           child:Text("Sign In",style:TextStyle(
            //fontSize:26,
               fontSize: screenWidth * 0.065, 
            fontWeight:FontWeight.bold) ,),
            ),
              ),
               ),
              Positioned(
             bottom: screenHeight * 0.15,          
                left:0,
                right:0,
                child:Center(
             child:  RichText(
              text: TextSpan(
                children:[
                  TextSpan(text:"Don't have an account ? ",
                   style:TextStyle(
                    fontWeight:FontWeight.bold,
                    color:Colors.white,
                   // fontSize:24,
                     fontSize: screenWidth * 0.055,
                  )
                  ),
                TextSpan(
                  text:"Sign Up",
                  style:TextStyle(
                    color:Colors.white,
                   // fontSize:26,
                     fontSize: screenWidth * 0.060,
                    fontWeight:FontWeight.bold,
                    decoration:TextDecoration.underline
                )   ,  
                recognizer: TapGestureRecognizer()
                  ..onTap = (){
                  Navigator.push(context, MaterialPageRoute(builder:(context)=>SignUpScreen()));
                }

              )
          
                ]  //children
              )  
             )  
                )
              )  
        ]  //children of stack
      )  
    );    
      





  }
}