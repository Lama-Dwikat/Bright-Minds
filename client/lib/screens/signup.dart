import 'package:flutter/material.dart';
import 'package:bright_minds/screens/signin.dart';
import 'package:bright_minds/widgets/sign.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart'; // For MediaType
import 'package:file_selector/file_selector.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;



class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {







String getBackendUrl() {
  if (kIsWeb) {
    // For web, use localhost or network IP
    //return "http://localhost:5000"; 
    return "http://192.168.1.122:3000";

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

  final _formSignUpKey = GlobalKey<FormState>();

  String? selectedRole;
  bool agreePersonalData = true;

XFile? _profileXFile;
XFile? _cvXFile;


  // Controllers
  // any thing that user will input
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController profilePicController = TextEditingController();
  final TextEditingController cvController = TextEditingController();
 // final TextEditingController parentCodeController = TextEditingController();

  String? ageGroup;
  String cvStatus = "pending"; // default value
DateTime? selectedDOB; // declare at the top of your State class


  bool _isNotValidate = false;





Future<void> pickProfileImage() async {
  final XTypeGroup pngTypeGroup = XTypeGroup(label: 'images', extensions: ['png', 'PNG']);
  final XFile? file = await openFile(acceptedTypeGroups: [pngTypeGroup]);
  if (file != null) {
    setState(() {
      _profileXFile = file;
    });
    print("✅ PNG selected: ${file.path}");
  }
}

Future<void> pickCV() async {
  final XTypeGroup pdfTypeGroup = XTypeGroup(label: 'PDF', extensions: ['pdf']);
  final XFile? file = await openFile(acceptedTypeGroups: [pdfTypeGroup]);
  if (file != null) {
    setState(() {
      _cvXFile = file;
    });
    print("✅ PDF selected: ${file.path}");
  }
}







  void  SignUp() async {
   
    if (selectedRole != null && selectedRole == "parent") {
      if (nameController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty
        ){

     String? profileBase64;
if (_profileXFile != null) {
  final profileBytes = await _profileXFile!.readAsBytes();
  profileBase64 = base64Encode(profileBytes);
}


            var SignUpBody={
              "name":nameController.text,
              "email":emailController.text,
              "password":passwordController.text,
              "age":null,
              "ageGroup":null,
              "role":selectedRole,
              "cvStatus":null,
              "profilePicture":profileBase64,
   
            };
          

            try{
           
      // API call to create user
      var response = await http.post(
        Uri.parse('${getBackendUrl()}/api/users/createUser'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(SignUpBody),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account Created Successfully!")),
        );
      }
        else {
           var body = jsonDecode(response.body);
          String errorMsg = body['error'] ?? 'An unexpected error occurred';
  
      if (response.statusCode == 400 && errorMsg.contains('Email already exists')) {
      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("This email already exists. Please use another email.")),
    );
               } else {
           ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(errorMsg)),
         );
           }
           }

             // print (response.statusCode);
            }
            catch(e){
              print("Exception: $e");
            }
        }

        else{
          print("Please fill all required fields for parent");
          setState((){
            _isNotValidate=true;
            });
        }
 
    }
   
else if (selectedRole != null && selectedRole == "child") {
  if (nameController.text.isNotEmpty &&
      emailController.text.isNotEmpty &&
      passwordController.text.isNotEmpty &&
      ageController.text.isNotEmpty) {

    // Encode profile picture as Base64 if selected
 String? profileBase64;
if (_profileXFile != null) {
  final profileBytes = await _profileXFile!.readAsBytes();
  profileBase64 = base64Encode(profileBytes);
}


    var SignUpBody = {
      "name": nameController.text,
      "email": emailController.text,
      "password": passwordController.text,
      "age": selectedDOB?.toIso8601String(), // send proper date
      "ageGroup": ageGroup,
      "role": selectedRole,
      "cvStatus": null,
      "profilePicture": profileBase64, // Send Base64 in JSON
      "cv": null,                      // Children don’t send CV
    };

    try {
      // API call to create user
      var response = await http.post(
        Uri.parse('${getBackendUrl()}/api/users/createUser'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(SignUpBody),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account Created Successfully!")),
        );
      } else {
        var body = jsonDecode(response.body);
        String errorMsg = body['error'] ?? 'An unexpected error occurred';

        if (response.statusCode == 400 && errorMsg.contains('Email already exists')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("This email already exists. Please use another email.")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      }
    } catch (e) {
      print("Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sign up failed")),
      );
    }
  } else {
    print("Please fill all required fields for child");
    setState(() {
      _isNotValidate = true;
    });
  }
}


  if (selectedRole == "supervisor") {
    if (nameController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        _cvXFile != null) {  // Use _cvFile instead of cvController.text


  String? profileBase64;
if (_profileXFile != null) {
  final profileBytes = await _profileXFile!.readAsBytes();
  profileBase64 = base64Encode(profileBytes);
}

String? cvBase64;
if (_cvXFile != null) {
  final cvBytes = await _cvXFile!.readAsBytes();
  cvBase64 = base64Encode(cvBytes);
}

      var SignUpBody = {
        "name": nameController.text,
        "email": emailController.text,
        "password": passwordController.text,
        "role": selectedRole,
        "cvStatus": cvStatus,
        "profilePicture": profileBase64, // Send Base64 in JSON
        "cv":cvBase64,

      };

      try {
        var response = await http.post(
         // Uri.parse(createUser),
          Uri.parse('${getBackendUrl()}/api/users/createUser'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(SignUpBody),
        );

          if (response.statusCode == 201) {
        //     // Success
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Account Created Successfully!")),
               );
            }
      else {
          var body = jsonDecode(response.body);
          String errorMsg = body['error'] ?? 'An unexpected error occurred';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
        }

      } catch (e) {
        print("Exception: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sign up failed")),
        );
      }

    } else {
      print("Please fill all required fields for supervisor");
      setState(() {
        _isNotValidate = true;
      });
    }
  }
    
      
  }

  @override
  Widget build(BuildContext context) {
    return Sign(
      child: Column(
        children: [
          const Expanded(flex: 2, child: SizedBox(height: 10)),
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25.5, 50.0, 25.0, 20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formSignUpKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Create a new account",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          color: Color.fromARGB(137, 8, 0, 0),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Name
                      TextFormField(
                        controller: nameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your name";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          label: const Text("Name"),
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Role Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: InputDecoration(
                          labelText: "Role",
                          prefixIcon: const Icon(Icons.people),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: "child", child: Text("Child")),
                          DropdownMenuItem(value: "parent", child: Text("Parent")),
                          DropdownMenuItem(value: "supervisor", child: Text("Supervisor")),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedRole = value;
                          });
                        },
                        validator: (value) => value == null ? "Please select a role" : null,
                      ),
                      const SizedBox(height: 20),

                      // Email ( for parent & supervisor & child )
                     // if (selectedRole == "parent" || selectedRole == "supervisor" || selectedRole == "child") ...[
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
                            label: const Text("Email"),
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                     // ],

                      // Password (for all)
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        obscuringCharacter: '*',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your password";
                          }
                         /* if (value.length < 6) {
                            return "Password must be at least 6 characters";
                          }*/
                          return null;
                        },
                        decoration: InputDecoration(
                          label: const Text("Password"),
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Age (for child only)
                      if (selectedRole == "child") ...[
                        TextFormField(
                        controller: ageController,
                         readOnly: true,
                        decoration:InputDecoration(
                          labelText:"Date of Birth",
                          prefixIcon:const Icon(Icons.cake_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        // onTap:()async{
                        //   DateTime today=DateTime.now();
                        //   DateTime firstDate=DateTime(today.year-12);
                        //   DateTime lastDate=DateTime(today.year-5);

                        //   DateTime? pickedDate=await showDatePicker(
                        //     context:context,
                        //     initialDate:firstDate,
                        //     firstDate:firstDate,
                        //     lastDate:lastDate,
                        //     );
                        //     if(pickedDate!=null){
                        //       setState((){
                        //         ageController.text="${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                        //         int age=today.year-pickedDate.year;
                        //         if(today.month<pickedDate.month || (today.month==pickedDate.month && today.day<pickedDate.day)){
                        //           age--;
                        //         }
                        //         if(age>=5 && age<=8){
                        //           ageGroup="5-8";
                        //         }
                        //         else if(age>=9 && age<=12){
                        //           ageGroup="9-12";
                        //         }else{
                        //           ageGroup=null;
                        //         }
                        //       });
                        //     }
                        // }
                        onTap: () async {
  DateTime today = DateTime.now();
  DateTime firstDate = DateTime(today.year - 12);
  DateTime lastDate = DateTime(today.year - 5);

  DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: firstDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );

  if (pickedDate != null) {
    setState(() {
      selectedDOB = pickedDate;
      ageController.text = "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";

      int age = today.year - pickedDate.year;
      if (today.month < pickedDate.month || (today.month == pickedDate.month && today.day < pickedDate.day)) {
        age--;
      }
      if (age >= 5 && age <= 8) {
        ageGroup = "5-8";
      } else if (age >= 9 && age <= 12) {
        ageGroup = "9-12";
      } else {
        ageGroup = null;
      }
    });
  }
}

                        ),
                        const SizedBox(height: 20),

                      ],

         

// Profile Picture Picker
GestureDetector(
  onTap: pickProfileImage,
  child: Container(
    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _profileXFile!= null
              ? _profileXFile!.path.split('/').last
              : "Select Profile Picture (PNG)",
          style: const TextStyle(fontSize: 16),
        ),
        _profileXFile != null
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.upload_file, color: Colors.deepPurple),
      ],
    ),
  ),
),
const SizedBox(height: 20),


                  // CV (Supervisor only)
            // CV (Supervisor only)
if (selectedRole == "supervisor") ...[
  GestureDetector(
    onTap: pickCV,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: _cvXFile == null && _isNotValidate ? Colors.red : Colors.grey,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _cvXFile != null
                ? _cvXFile!.path.split('/').last
                : "Select CV (PDF)",
            style: TextStyle(
              fontSize: 16,
              color: _cvXFile == null && _isNotValidate ? Colors.red : Colors.black,
            ),
          ),
          _cvXFile != null
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.upload_file, color: Colors.deepPurple),
        ],
      ),
    ),
  ),
  // Error message
  if (_cvXFile == null && _isNotValidate)
    const Padding(
      padding: EdgeInsets.only(top: 5),
      child: Text(
        "CV is required",
        style: TextStyle(color: Colors.red, fontSize: 12),
      ),
    ),
  const SizedBox(height: 10),



                      ],



                      // Agree personal data checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: agreePersonalData,
                            onChanged: (bool? value) {
                              setState(() {
                                agreePersonalData = value!;
                              });
                            },
                          ),
                          const Expanded(
                            child: Text(
                              "I agree to the processing of personal data",
                              style: TextStyle(color: Colors.black45),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),




                      // Sign Up button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                     if (_formSignUpKey.currentState!.validate() && agreePersonalData) {
    SignUp();
               } else if (!agreePersonalData) {
                   ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text("Please agree to personal data processing")),
                 );
                }
             },
     
                          child: const Text("Sign Up"),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Already have account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SignInScreen()),
                              );
                            },
                            child: const Text(
                              "Sign In",
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
