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
      decoration:BoxDecoration(
  color:Colors.white,
  borderRadius:BorderRadius.only(
    topLeft:Radius.circular(40),
    topRight:Radius.circular(40),
      )
       ),
       child:Form(
      key:_formSignInKey,
        child:Column(
     crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text("- Every login is a new beginning – ",style:TextStyle(
        fontSize:25,
        fontWeight:FontWeight.w900,
        color:Colors.black54,
      )
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
borderSide: BorderSide(color:Colors.black12),
)
    )
    ),
    TextFormField(
      obscureText: true,
      obscuringCharacter: '*',
      validator:(value){
        if(value==null || value.isEmpty){
          return 'Enter your Password';
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
      height:10),
      Row(
         mainAxisAlignment:MainAxisAlignment.spaceBetween,
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
      
            GestureDetector(
              child:Text("Forget Password ?",style:TextStyle(
                fontWeight: FontWeight.bold,
                color:Colors.deepPurple,
              ))
            )


          
        
      ],
      )
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


       
      