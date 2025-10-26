import 'package:flutter/material.dart';
import "package:bright_minds/widgets/sign.dart";
import 'package:bright_minds/screens/signup.dart';
import 'package:icons_plus/icons_plus.dart';
import '../theme/theme.dart';









class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formSignInKey=GlobalKey<FormState>();
  bool rememberPassword=true;
  @override
  Widget build(BuildContext context) {
    return Sign(
     
     child:Column(children: [
      Expanded(
        flex:2,
        child:SizedBox(height:10),
         ),
         Expanded(
          flex:6,
          child:Container(
            padding: const EdgeInsets.fromLTRB(25.5, 50.0, 25.0, 20.0),
      decoration:BoxDecoration(
  color:Colors.white,
  borderRadius:BorderRadius.only(
    topLeft:Radius.circular(40),
    topRight:Radius.circular(40),
      )
       ),
child:SingleChildScrollView(
       child:Form(
      key:_formSignInKey,
        child:Column(
     crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(" Every login is a new beginning  ",style:TextStyle(
        fontSize:25,
        fontWeight:FontWeight.w900,
        color:Color.fromARGB(137, 8, 0, 0),
      )
      ),
      const SizedBox(
               height:30,
             ),
        
        
        
      
TextFormField(
  validator: (value){
if(value==null || value.isEmpty){
  return "Please Enter your Username";
  }
  return null;
  },
  decoration:InputDecoration(
    label:Text("Username"),
    hintText:"Enter your Username",
    hintStyle:TextStyle(
      color:Colors.black26,
    ),
    prefixIcon: Icon(
      Icons.person,
      color:Colors.black26,
    ),
    
    border:OutlineInputBorder(
      borderSide:BorderSide(color: Colors.black12),
      borderRadius:BorderRadius.circular(10),
      ),
     enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color:Colors.black12
    ),
    borderRadius:BorderRadius.circular(10),
    )
    )
    ),
    const SizedBox(
               height:30,
             ),
    TextFormField(
      obscureText: true,
      obscuringCharacter: '*',
      validator:(value){
        if(value==null || value.isEmpty){
          return 'Please Enter your Password';
        }
        return null;
        },decoration:InputDecoration(
          label:Text("Password"),
          hintText:"Enter Password",
          hintStyle:TextStyle(
            color:Colors.black26,
          ),
          prefixIcon: Icon(
            Icons.password,
            color:Colors.black26
          ),
          border:OutlineInputBorder(
            borderSide:BorderSide(
              color:Colors.black12,
            ),
            borderRadius:BorderRadius.circular(10)
          ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color:Colors.black12),
         )
    )
    ),
    SizedBox(
      height:30),
      Row(
         mainAxisAlignment:MainAxisAlignment.spaceBetween,
        children: [
      Row(
        children: [
       Checkbox(
        value: rememberPassword,
        onChanged: (bool? value){
          setState((){
            rememberPassword=value!;
            }
            );
            },
           
       ),
            Text("Remember Me", style:TextStyle(
              color:Colors.black45,
            ),
            ),
        ],
      ),
            GestureDetector(
              child:Text("Forget Password ?",style:TextStyle(
                fontWeight: FontWeight.bold,
                color:Colors.deepPurple,
              ))
            )


          
        
      ],
      ),
      const SizedBox(height: 30,),
      SizedBox(
        width:double.infinity,
        child:ElevatedButton(
          onPressed: (){
            if(_formSignInKey.currentState!.validate() && rememberPassword){
              //process data
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:Text('Processing Data')
                  ),
              );
            } 
            else if (!rememberPassword){
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:Text('Please agree to the processing of personal data')
                  ),
              );
            }
          }, 
          child: const Text('Sign In')
          ),
        ),
        const SizedBox(height:30),
       
                      // Already have account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SignUpScreen()),
                              );
                            },
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Colors.deepPurple,
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
  }
}


       
      