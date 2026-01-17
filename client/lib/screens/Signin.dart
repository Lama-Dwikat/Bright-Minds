import 'package:flutter/material.dart';
import "package:bright_minds/widgets/sign.dart";
import 'package:bright_minds/screens/signup.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bright_minds/screens/homeParent.dart';
import 'package:bright_minds/screens/homeChild.dart';
import 'package:bright_minds/screens/homeSupervisor.dart';
import 'package:bright_minds/screens/homeAdmin.dart';
import 'package:bright_minds/widgets/home.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bright_minds/theme/colors.dart';














class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formSignInKey=GlobalKey<FormState>();
  bool rememberPassword=true;


TextEditingController emailController=TextEditingController();
TextEditingController passwordController=TextEditingController();
bool _isNotValidate = false;


String getBackendUrl() {
  if (kIsWeb) {

    return "http://192.168.1.63:3000";

  } else if (Platform.isAndroid) {
    // Android emulator
    return "http://10.0.2.2:3000";
  } else if (Platform.isIOS) {
    // iOS emulator
    return "http://localhost:3000";
  } else {
    // fallback
    return "http://localhost:3000";
  }
}



  void SignIn() async {
   if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
    var SignInBody = {
      "email": emailController.text,
      "password": passwordController.text
    };

    try {
      var response = await http.post(
          Uri.parse('${getBackendUrl()}/api/users/signIn'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(SignInBody),
      );


     if (response.statusCode == 200) {
  var data = jsonDecode(response.body);
  var token = data['token'];
  var userRole = data['user']['role'];
  var userName = data['user']['name'];
  var userId = data['user']['id'];

  SharedPreferences prefs = await SharedPreferences.getInstance();
  //prefs.clear();

  print("TOKEN SAVED AFTER LOGIN: $token");

  // احفظي التوكن قبل أي انتقال
  await prefs.setString('token', token);
  await prefs.setString('userName', userName);
  await prefs.setString('userId', userId);
  prefs.setString("userRole", userRole);   


  print("User role: $userRole");

  // الآن الانتقال
  Widget nextPage;

  if (userRole == 'parent') {
    nextPage = HomeParent();
  } else if (userRole == 'supervisor') {
    if (data['user']['cvStatus'] != 'approved') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your CV is not approved yet.')),
      );
      return;
    }
    nextPage = HomeSupervisor();
  } else if (userRole == 'child') {
    nextPage = HomeChild();
  } else if (userRole == 'admin') {
    nextPage = HomeAdmin();
  } else {
    return;
  }

  // استخدمي pushReplacement عشان ما يظل SignIn ويمسح الـ state
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => nextPage),
  );

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Sign in successful')),
  );
}

      else {
        var errorMsg = jsonDecode(response.body)['error'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $errorMsg')),
        );
      }
    } catch (e) {
      print("Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred during sign in')),
      );
    }
  } else {
    setState(() {
      _isNotValidate = true;
    });
  }
}



//   @override
//   Widget build(BuildContext context) {
//     return Sign(
     
//      child:Column(children: [
//       Expanded(
//         flex:2,
//         child:SizedBox(height:10),
//          ),
//          Expanded(
//           flex:6,
//           child:Container(
//             padding: const EdgeInsets.fromLTRB(25.5, 50.0, 25.0, 20.0),
//       decoration:BoxDecoration(
//   color:Colors.white,
//   borderRadius:BorderRadius.only(
//     topLeft:Radius.circular(40),
//     topRight:Radius.circular(40),
//       )
//        ),
//     child:SingleChildScrollView(
//        child:Form(
//       key:_formSignInKey,
//         child:Column(
//      crossAxisAlignment: CrossAxisAlignment.center,
//     children: [
//       Text(" Every login is a new beginning  ",style:TextStyle(
//         fontSize:25,
//         fontWeight:FontWeight.w900,
//         color:Color.fromARGB(135, 56, 44, 17),
//       )
//       ),
//       const SizedBox(
//                height:30,
//              ),
        
        
        
      
// TextFormField(
//    controller: emailController,
//    validator: (value) {
//  if (value == null || value.isEmpty) {
//     return "Please enter your email";
//      }
//  if (!value.contains('@')) return "Invalid email";
//   return null;
// },
//   decoration:InputDecoration(
//     label:Text("Email"),
//     hintText:"Enter your Email",
//     hintStyle:TextStyle(
//       color:Colors.black26,
//     ),
//     prefixIcon: Icon(
//       Icons.email,
//       color:Colors.black26,
//     ),
    
//     border:OutlineInputBorder(
//       borderSide:BorderSide(color: Colors.black12),
//       borderRadius:BorderRadius.circular(10),
//       ),
//      enabledBorder: OutlineInputBorder(
//     borderSide: BorderSide(color:Colors.black12
//     ),
//     borderRadius:BorderRadius.circular(10),
//     )
//     )
//     ),


//     const SizedBox(
//                height:30,
//              ),



//     TextFormField(
//       controller: passwordController,
//       obscureText: true,
//       obscuringCharacter: '*',
//       validator:(value){
//         if(value==null || value.isEmpty){
//           return 'Please Enter your Password';
//         }
//         return null;
//         },decoration:InputDecoration(
//           label:Text("Password"),
//           hintText:"Enter Password",
//           hintStyle:TextStyle(
//            // color:const Color.fromARGB(111, 0, 0, 0),
//            color:AppColors.bgBlushRoseVeryDark,
//           ),

//           prefixIcon:const Icon(
//             (Icons.lock_outline),
//            // color:Color.fromARGB(111, 0, 0, 0)
//                       color:AppColors.bgBlushRoseVeryDark,

//           ),
//           border:OutlineInputBorder(
//             borderSide:BorderSide(
//              // color:const Color.fromARGB(77, 0, 0, 0),
//                         color:AppColors.bgBlushRoseVeryDark,

//             ),
//             borderRadius:BorderRadius.circular(10)
//           ),
//       enabledBorder: OutlineInputBorder(
//         borderSide: BorderSide(color:AppColors.bgBlushRoseVeryDark),
//          )
//     )
//     ),
//     SizedBox(
//       height:30),
//       Row(
//          mainAxisAlignment:MainAxisAlignment.spaceBetween,
//         children: [
//       Row(
//         children: [
//        Checkbox(
//         value: rememberPassword,
//         onChanged: (bool? value){
//           setState((){
//             rememberPassword=value!;
//             }
//             );
//             },
           
//        ),
//             Text("Remember Me", style:TextStyle(
//               color:Colors.black45,
//             ),
//             ),
//         ],
//       ),
//             GestureDetector(
//               child:Text("Forget Password ?",style:TextStyle(
//                 fontWeight: FontWeight.bold,
         
//               color:AppColors.bgBlushRoseVeryDark,

//               ))
//             )


          
        
//       ],
//       ),
//       const SizedBox(height: 30,),
//       SizedBox(
//         width:double.infinity,
//         child:ElevatedButton(
//           onPressed: (){
//             if(_formSignInKey.currentState!.validate() && rememberPassword){
      
//               print("Sign In button pressed");

//               SignIn();
//             } 
//             else if (!rememberPassword){
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content:Text('Please agree to the processing of personal data')
//                   ),
//               );
//             }
//           }, 
//          /* onTap:()=>{
//             SignIn(),
//           },*/
//           child: const Text('Sign In')
//           ),
//         ),
//         const SizedBox(height:30),
       
//                       // Already have account
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Text("Don't have an account? "),
//                           GestureDetector(
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => const SignUpScreen()),
//                               );
//                             },
//                             child: const Text(
//                               "Sign Up",
//                               style: TextStyle(
//                                color:AppColors.bgBlushRoseVeryDark,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
       
//        ],
//         ),
//        ),
//        ),
//        ),
//           ),
//      ],
//          ),
//      );
//   }
// }


       
      

      @override
Widget build(BuildContext context) {
  final Size screenSize = MediaQuery.of(context).size;
  final double screenHeight = screenSize.height;
  final double screenWidth = screenSize.width;

  final bool isMobile = screenWidth < 600; // breakpoint

  // MOBILE DESIGN (UNCHANGED)
  Widget mobileSignIn = Sign(
    child: Column(
      children: [
        Expanded(flex: 2, child: SizedBox(height: 10)),
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.fromLTRB(25.5, 50.0, 25.0, 20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formSignInKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Every login is a new beginning",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: Color.fromARGB(135, 56, 44, 17),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Email Field
                    TextFormField(
                      controller: emailController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your email";
                        }
                        if (!value.contains('@')) return "Invalid email";
                        return null;
                      },
                      decoration: InputDecoration(
                        label: Text("Email"),
                        hintText: "Enter your Email",
                        hintStyle: TextStyle(color: Colors.black26),
                        prefixIcon: Icon(Icons.email, color: Colors.black26),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Password Field
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      obscuringCharacter: '*',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please Enter your Password';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        label: Text("Password"),
                        hintText: "Enter Password",
                        hintStyle: TextStyle(
                          color: AppColors.bgBlushRoseVeryDark,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.bgBlushRoseVeryDark,
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.bgBlushRoseVeryDark,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.bgBlushRoseVeryDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Remember Me & Forget Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: rememberPassword,
                              onChanged: (bool? value) {
                                setState(() {
                                  rememberPassword = value!;
                                });
                              },
                            ),
                            Text(
                              "Remember Me",
                              style: TextStyle(color: Colors.black45),
                            ),
                          ],
                        ),
                        GestureDetector(
                          child: Text(
                            "Forget Password?",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.bgBlushRoseVeryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formSignInKey.currentState!.validate() &&
                              rememberPassword) {
                            SignIn();
                          } else if (!rememberPassword) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please agree to the processing of personal data')),
                            );
                          }
                        },
                        child: const Text('Sign In'),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignUpScreen()),
                            );
                          },
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              color: AppColors.bgBlushRoseVeryDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // WEB/DESKTOP DESIGN
  Widget webSignIn = Row(
    children: [
      // Left Image
      Expanded(
        child: Image.asset(
          "assets/images/welcome.png",
          fit: BoxFit.cover,
          height: screenHeight,
        ),
      ),
      // Right Form
      Expanded(
       child: Container(
          color: const Color.fromARGB(255, 250, 225, 190), 
        child: Center(
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formSignInKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Every login is a new beginning",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Email Field
                    TextFormField(
                      controller: emailController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your email";
                        }
                        if (!value.contains('@')) return "Invalid email";
                        return null;
                      },
                      decoration: InputDecoration(
                        label: Text("Email"),
                        hintText: "Enter your Email",
                        prefixIcon: Icon(Icons.email, color: Colors.black26),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Password Field
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      obscuringCharacter: '*',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please Enter your Password';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        label: Text("Password"),
                        hintText: "Enter Password",
                        prefixIcon: Icon(Icons.lock_outline,
                            color: AppColors.bgBlushRoseVeryDark),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Remember Me Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: rememberPassword,
                          onChanged: (bool? value) {
                            setState(() {
                              rememberPassword = value!;
                            });
                          },
                        ),
                        Text(
                          "Remember Me",
                          style: TextStyle(color: Colors.black45),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Sign In Button
                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 250, 225, 190),
                        ),
                        onPressed: () {
                          if (_formSignInKey.currentState!.validate() &&
                              rememberPassword) {
                            SignIn();
                          } else if (!rememberPassword) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please agree to the processing of personal data')),
                            );
                          }
                        },
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignUpScreen()),
                            );
                          },
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    ],
  );

  // Return mobile or web layout
  return Scaffold(
    body: isMobile ? mobileSignIn : webSignIn,
  );
}
}