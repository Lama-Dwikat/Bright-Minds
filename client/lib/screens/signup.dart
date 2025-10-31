import 'package:flutter/material.dart';
import 'package:bright_minds/screens/signin.dart';
import 'package:bright_minds/widgets/sign.dart';
import 'package:bright_minds/config.dart';
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
    return "http://127.0.0.1:3000"; // or your LAN IP like 192.168.1.10
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

  File? _profileImage;
  File? _cvFile;


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


  bool _isNotValidate = false;




 Future<void> pickProfileImage() async {
  const XTypeGroup pngTypeGroup = XTypeGroup(
    label: 'images',
    extensions: ['png', 'PNG'],
  );

  final XFile? file = await openFile(acceptedTypeGroups: [pngTypeGroup]);

  if (file != null) {
    setState(() {
      _profileImage = File(file.path);
    });
    print("✅ PNG selected: ${file.path}");
  } else {
    print("No file selected.");
  }
}

// In pickCV()
Future<void> pickCV() async {
  // Allow only PDF files
  const XTypeGroup typeGroup = XTypeGroup(
    label: 'PDF',
    extensions: ['pdf'],
  );

  final XFile? file = await openFile(
    acceptedTypeGroups: [typeGroup],
  );

  if (file != null) {
    setState(() {
      _cvFile = File(file.path);
      cvStatus = "Selected";
    });
    print("CV selected: ${_cvFile!.path}");
  } else {
    print("No file selected.");
  }
}



Future<void> uploadFiles(String userId) async {
  if (_profileImage == null && _cvFile == null) return; // nothing to upload

  try {
    var request = http.MultipartRequest(
      'POST',
     // Uri.parse('http://10.0.2.2:3000/api/users/upload/$userId'),
       Uri.parse('${getBackendUrl()}/api/users/upload/$userId'),
    );

    if (_profileImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profilePicture',
        _profileImage!.path,
        contentType: MediaType('image', 'png'),
      ));
    }

  if (_cvFile != null) {
  request.files.add(await http.MultipartFile.fromPath(
    'cv',
    _cvFile!.path,
    contentType: MediaType('application', 'pdf'), // matches backend
  ));
}


    var response = await request.send();
    if (response.statusCode == 200) {
      print("Files uploaded successfully!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Files uploaded successfully!")),
      );
    } else {
      print("Upload failed: ${response.statusCode}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: ${response.statusCode}")),
      );
    }
  } catch (e) {
    print("Upload error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Upload error")),
    );
  }
}






  void  SignUp() async {
   
    if (selectedRole != null && selectedRole == "parent") {
      if (nameController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty
        ){

            var SignUpBody={
              "name":nameController.text,
              "email":emailController.text,
              "password":passwordController.text,
              "age":null,
              "ageGroup":null,
             // "profilePicture":profilePicController.text,
              "role":selectedRole,
              "cvStatus":null,
              
            };
          

            try{
              // API call to register parent
              print ("profilePicture: ${profilePicController.text}");
              var response = await http.post(Uri.parse(createUser),
              headers: {"Content-Type":"application/json"}, 
              body: jsonEncode(SignUpBody)
              );

                if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account Created Successfully!")),
          );

          var body = jsonDecode(response.body);
          var userId = body['_id']; // Backend user ID

          // Upload files
          var uploadRequest = http.MultipartRequest(
            'POST',
            Uri.parse('${getBackendUrl()}/api/users/upload/$userId'),
          );

          if (_profileImage != null) {
            uploadRequest.files.add(await http.MultipartFile.fromPath(
              'profilePicture',
              _profileImage!.path,
              contentType: MediaType('image', 'png'),
            ));
          }

     try {
  var streamedResponse = await uploadRequest.send();
  var response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Files uploaded successfully!")),
    );
  } else {
    var body = jsonDecode(response.body);
    String errorMsg = body['error'] ?? 'File upload failed';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("File upload failed: $errorMsg")),
    );
  }
} catch (e) {
  print("Upload exception: $e");
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("File upload error")),
  );
}


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
        passwordController.text.isNotEmpty&&
        ageController.text.isNotEmpty){

            var SignUpBody={
              "name":nameController.text,
              "email":emailController.text,
              "password":passwordController.text,
              "age":ageController.text,
              "ageGroup":ageGroup,
            //  "profilePicture":profilePicController.text,
              "role":selectedRole,
              "cvStatus":null,
            };

             try{
              // API call to register parent
                print ("profile pic: ${profilePicController.text}");
               var response = await http.post(Uri.parse(createUser),
              headers: {"Content-Type":"application/json"}, 
              body: jsonEncode(SignUpBody)
              );
             // print (response.statusCode);
        //      if (response.statusCode == 201) {
        //     // Success
        // ScaffoldMessenger.of(context).showSnackBar(
        //    const SnackBar(content: Text("Account Created Successfully!")),
        //        );
        //     }
               if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account Created Successfully!")),
          );

          var body = jsonDecode(response.body);
          var userId = body['_id']; // Backend user ID

          // Upload files
          var uploadRequest = http.MultipartRequest(
            'POST',
            Uri.parse('${getBackendUrl()}/api/users/upload/$userId'),
          );

          if (_profileImage != null) {
            uploadRequest.files.add(await http.MultipartFile.fromPath(
              'profilePicture',
              _profileImage!.path,
              contentType: MediaType('image', 'png'),
            ));
          }

          if (_cvFile != null) {
            uploadRequest.files.add(await http.MultipartFile.fromPath(
              'cv',
              _cvFile!.path,
              contentType: MediaType('application', 'pdf'),
            ));
          }

          var uploadResponse = await uploadRequest.send();
          if (uploadResponse.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Files uploaded successfully!")),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("File upload failed: ${uploadResponse.statusCode}")),
            );
          }
        }
         else {
              var body = jsonDecode(response.body);
        String errorMsg = body['error'] ?? 'An unexpected error occurred';
  
       if (response.statusCode == 400 && errorMsg.contains('Email already exists')) {
         ScaffoldMessenger.of(context).showSnackBar(     const SnackBar(content: Text("This email already exists. Please use another email.")),
                     );
        } else {
         ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMsg)),
           );
         }
           }

            }
            catch(e){
              print("Exception: $e");
            }
        }
        else {
          print("Please fill all required fields for child");
          setState((){
            _isNotValidate=true;
            });
        }
 
    }
//     else if (selectedRole != null && selectedRole == "supervisor") {
//       if (nameController.text.isNotEmpty &&
//         emailController.text.isNotEmpty &&
//         passwordController.text.isNotEmpty&&
//         cvController.text.isNotEmpty
//         ){

//             var SignUpBody={
//               "name":nameController.text,
//               "email":emailController.text,
//               "password":passwordController.text,
//               "age":null,
//               "ageGroup":null,
//            //   "profilePicture":profilePicController.text,
//               "role":selectedRole,
//             //  "cv":cvController.text,
//               "cvStatus":cvStatus,
//             };

            

//              try{
//               // API call to register parent
//                //  print ("cvController.text ${cvController.text}");
//                var response = await http.post(Uri.parse(createUser),
//               headers: {"Content-Type":"application/json"}, 
//               body: jsonEncode(SignUpBody)
//               );
//             //  print (response.statusCode);
//             // if (response.statusCode == 201) { // Success
//             // ScaffoldMessenger.of(context).showSnackBar(
//             //   const SnackBar(content: Text("Account Created Successfully!")),
//             //   );
//             // } 
//     if (response.statusCode == 201) {
//   ScaffoldMessenger.of(context).showSnackBar(
//     const SnackBar(content: Text("Account Created Successfully!")),
//   );

//   // Upload files if selected
//   if (_profileImage != null || _cvFile != null) {
//     try {
//       var body = jsonDecode(response.body);
//       var userId = body['_id']; // ID of created user

//       var uploadRequest = http.MultipartRequest(
//         'POST',
//         Uri.parse('http://10.0.2.2:3000/api/users/upload/$userId'), // backend route
//       );

//       if (_profileImage != null) {
//         uploadRequest.files.add(await http.MultipartFile.fromPath(
//           'profilePicture',
//           _profileImage!.path,
//           contentType: MediaType('image', 'png'),
//         ));
//       }

//       if (_cvFile != null) {
//         uploadRequest.files.add(await http.MultipartFile.fromPath(
//           'cv',
//           _cvFile!.path,
//           contentType: MediaType('application', 'pdf'),
//         ));
//       }

//       var uploadResponse = await uploadRequest.send();
//       if (uploadResponse.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Files uploaded successfully!")),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("File upload failed: ${uploadResponse.statusCode}")),
//         );
//       }
//     } catch (e) {
//       print("File upload error: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("File upload error")),
//       );
//     }
//   }
// }


            
//             else {
//           var body = jsonDecode(response.body);
//           String errorMsg = body['error'] ?? 'An unexpected error occurred';
  
//        if (response.statusCode == 400 && errorMsg.contains('Email already exists')) {
//        ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("This email already exists. Please use another email.")),
//             );
//           } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//            SnackBar(content: Text(errorMsg)),
//          );
//       }
//       }







//             }
//             catch(e){
//               print("Exception: $e");
//             }
//         }
//         else {
//           print("Please fill all required fields for supervisor");
//           setState((){
//             _isNotValidate=true;
//             });
//         }
 
//     }





  if (selectedRole == "supervisor") {
    if (nameController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        _cvFile != null) {  // Use _cvFile instead of cvController.text

      var SignUpBody = {
        "name": nameController.text,
        "email": emailController.text,
        "password": passwordController.text,
        "role": selectedRole,
        "cvStatus": cvStatus,
      };

      try {
        var response = await http.post(
          Uri.parse(createUser),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(SignUpBody),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account Created Successfully!")),
          );

          var body = jsonDecode(response.body);
          var userId = body['_id']; // Backend user ID

          // Upload files
          var uploadRequest = http.MultipartRequest(
            'POST',
            Uri.parse('${getBackendUrl()}/api/users/upload/$userId'),
          );

          if (_profileImage != null) {
            uploadRequest.files.add(await http.MultipartFile.fromPath(
              'profilePicture',
              _profileImage!.path,
              contentType: MediaType('image', 'png'),
            ));
          }

          if (_cvFile != null) {
            uploadRequest.files.add(await http.MultipartFile.fromPath(
              'cv',
              _cvFile!.path,
              contentType: MediaType('application', 'pdf'),
            ));
          }

          var uploadResponse = await uploadRequest.send();
          if (uploadResponse.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Files uploaded successfully!")),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("File upload failed: ${uploadResponse.statusCode}")),
            );
          }

        } else {
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
                        onTap:()async{
                          DateTime today=DateTime.now();
                          DateTime firstDate=DateTime(today.year-12);
                          DateTime lastDate=DateTime(today.year-5);

                          DateTime? pickedDate=await showDatePicker(
                            context:context,
                            initialDate:firstDate,
                            firstDate:firstDate,
                            lastDate:lastDate,
                            );
                            if(pickedDate!=null){
                              setState((){
                                ageController.text="${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                                int age=today.year-pickedDate.year;
                                if(today.month<pickedDate.month || (today.month==pickedDate.month && today.day<pickedDate.day)){
                                  age--;
                                }
                                if(age>=5 && age<=8){
                                  ageGroup="5-8";
                                }
                                else if(age>=9 && age<=12){
                                  ageGroup="9-12";
                                }else{
                                  ageGroup=null;
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
          _profileImage != null
              ? _profileImage!.path.split('/').last
              : "Select Profile Picture (PNG)",
          style: const TextStyle(fontSize: 16),
        ),
        _profileImage != null
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.upload_file, color: Colors.deepPurple),
      ],
    ),
  ),
),
const SizedBox(height: 20),


                  // CV (Supervisor only)
               if (selectedRole == "supervisor")  ...[

         GestureDetector(
    onTap: pickCV,
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
            _cvFile != null
                ? _cvFile!.path.split('/').last
                : "Select CV (PDF)",
            style: const TextStyle(fontSize: 16),
          ),
          _cvFile != null
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.upload_file, color: Colors.deepPurple),
        ],
      ),
    ),
  ),

                        const SizedBox(height: 10),


                        Row(
                          children: [
                            const Text("CV Status: "),
                            Text(
                              cvStatus,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),


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
