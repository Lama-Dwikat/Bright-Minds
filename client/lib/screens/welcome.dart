

import 'package:flutter/material.dart';
import 'package:bright_minds/screens/signin.dart';
import 'package:bright_minds/screens/signup.dart';
import 'package:flutter/gestures.dart';//to use TapGestureRecognizer for clickable text


class WelcomeScreen extends StatelessWidget {
  WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

   return  Scaffold(
      body:Stack(
        children:[
          Image.asset(("assets/images/mobile.png"), 
          fit:BoxFit.cover,
          width:double.infinity,
          height:double.infinity,
          ),
               Positioned(
                  bottom:220,
                  left:220,
                       
           child:   Container(
                width: 200,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color:Colors.white,
                ),
           child: MaterialButton(onPressed: (){
            Navigator.push(context,MaterialPageRoute(builder:(context)=>SignInScreen()));
           },
           textColor: Colors.deepPurple,
           child:Text("Sign In",style:TextStyle(fontSize:25,fontWeight:FontWeight.bold) ,),
            ),
              ),
               ),
              Positioned(
                bottom:130,
                left:0,
                  right:0,
                child:Center(
             child:  RichText(
              text: TextSpan(
                children:[
                  TextSpan(text:"Don't have an account ? ",
                   style:TextStyle(
                    color:Colors.white,
                    fontSize:22,
                  )
                  ),
                TextSpan(
                  text:"Sign Up",
                  style:TextStyle(
                    color:Colors.white,
                    fontSize:24,
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