

import 'package:flutter/material.dart';
import 'package:bright_minds/screens/signin.dart';
import 'package:bright_minds/screens/signup.dart';
import 'package:flutter/gestures.dart';//to use TapGestureRecognizer for clickable text
import 'package:bright_minds/theme/colors.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;



class WelcomeScreen extends StatelessWidget {
  WelcomeScreen({super.key});

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.63:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    if (Platform.isIOS) return "http://localhost:3000";
    return "http://localhost:3000";
  }
  // @override
  // Widget build(BuildContext context) {
  // final Size screenSize=MediaQuery.of(context).size;
  // final double screenHeight=screenSize.height;
  // final double screenWidth=screenSize.width;

  //  return  Scaffold(
  //     body:Stack(
  //       children:[
  //         Image.asset(("assets/images/welcome.png"), 
  //         fit:BoxFit.cover,
  //         width:screenWidth,
  //         height:screenHeight,
  //         ),
  //              Positioned(
  //             bottom: screenHeight * 0.22, // 25% from bottom
  //             left: screenWidth * 0.51 ,
  //          child:   Container(
  //             width: screenWidth * 0.43, // 40% of screen width
  //             height: screenHeight * 0.07, // 8% of screen height
  //               decoration: BoxDecoration(
  //                 borderRadius: BorderRadius.circular(10),
  //               color:Color.fromARGB(255, 250, 225, 190),
  //               ),
  //          child: MaterialButton(onPressed: (){
  //           Navigator.push(context,MaterialPageRoute(builder:(context)=>SignInScreen()));
  //          },
  //          textColor:  const Color.fromARGB(255, 160, 112, 95),

  //          child:Text("Sign In",style:TextStyle(
  //           //fontSize:26,
  //              fontSize: screenWidth * 0.065, 
  //           fontWeight:FontWeight.bold) ,),
  //           ),
  //             ),
  //              ),
  //             Positioned(
  //            bottom: screenHeight * 0.15,          
  //               left:0,
  //               right:0,
  //               child:Center(
  //            child:  RichText(
  //             text: TextSpan(
  //               children:[
  //                 TextSpan(text:"Don't have an account ? ",
  //                  style:TextStyle(
  //                   fontWeight:FontWeight.bold,
  //                   color:const Color.fromARGB(255, 191, 134, 113),
  //                  // fontSize:24,
  //                    fontSize: screenWidth * 0.055,
  //                 )
  //                 ),
  //               TextSpan(
  //                 text:"Sign Up",
  //                 style:TextStyle(
  //                   color:const Color.fromARGB(255, 191, 134, 113),
  //                  // fontSize:26,
  //                    fontSize: screenWidth * 0.060,
  //                   fontWeight:FontWeight.bold,
  //                   decoration:TextDecoration.underline
  //               )   ,  
  //               recognizer: TapGestureRecognizer()
  //                 ..onTap = (){
  //                 Navigator.push(context, MaterialPageRoute(builder:(context)=>SignUpScreen()));
  //               }

  //             )
          
  //               ]  //children
  //             )  
  //            )  
  //               )
  //             )  
  //       ]  //children of stack
  //     )  
  //   );    
      





  // }
//}


Widget build(BuildContext context) {
  final Size screenSize = MediaQuery.of(context).size;
  final double screenHeight = screenSize.height;
  final double screenWidth = screenSize.width;

  final bool isMobile = screenWidth < 600; // breakpoint

  return Scaffold(
    body: isMobile
        // ===================== MOBILE DESIGN (UNCHANGED) =====================
        ? Stack(
            children: [
              Image.asset(
                "assets/images/welcome.png",
                fit: BoxFit.cover,
                width: screenWidth,
                height: screenHeight,
              ),

              Positioned(
                bottom: screenHeight * 0.22,
                left: screenWidth * 0.51,
                child: Container(
                  width: screenWidth * 0.43,
                  height: screenHeight * 0.07,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color.fromARGB(255, 250, 225, 190),
                  ),
                  child: MaterialButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SignInScreen()),
                      );
                    },
                    textColor:
                        const Color.fromARGB(255, 160, 112, 95),
                    child: Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: screenWidth * 0.065,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: screenHeight * 0.15,
                left: 0,
                right: 0,
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Don't have an account ? ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                const Color.fromARGB(255, 191, 134, 113),
                            fontSize: screenWidth * 0.055,
                          ),
                        ),
                        TextSpan(
                          text: "Sign Up",
                          style: TextStyle(
                            color:
                                const Color.fromARGB(255, 191, 134, 113),
                            fontSize: screenWidth * 0.060,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => SignUpScreen()),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )

        // ===================== WEB / DESKTOP DESIGN =====================
        : Row(
            children: [
              // Left side image
              Expanded(
                child: Image.asset(
                  "assets/images/welcome.png",
                  fit: BoxFit.cover,
                  height: screenHeight,
                ),
              ),

              // Right side content
              Expanded(
                child: Container(
          color: const Color.fromARGB(255, 250, 225, 190), // background color behind the form
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 80),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Welcome to\nBright Minds",
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary ,
                        ),
                      ),

                      const SizedBox(height: 40),

                      SizedBox(
                        width: 300,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 245, 234, 218),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => SignInScreen()),
                            );
                          },
                          child: const Text(
                            "Sign In",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color:
                                  Color.fromARGB(255, 160, 112, 95),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: "Don't have an account? ",
                              style: TextStyle(
                                fontSize: 18,
                                color: Color.fromARGB(
                                    255, 191, 134, 113),
                              ),
                            ),
                            TextSpan(
                              text: "Sign Up",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                decoration:
                                    TextDecoration.underline,
                                color: Color.fromARGB(
                                    255, 191, 134, 113),
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            SignUpScreen()),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),
            ],
          ),
  );
}
}