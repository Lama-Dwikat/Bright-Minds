import 'package:flutter/material.dart';
import 'package:bright_minds/screens/signin.dart';
import 'package:bright_minds/widgets/sign.dart';
import 'package:bright_minds/theme/theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formSignUpKey = GlobalKey<FormState>();

  String? selectedRole;
  bool agreePersonalData = true;

  // Controllers
  /*final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController profilePicController = TextEditingController();
  final TextEditingController cvController = TextEditingController();
*/
  final TextEditingController ageController = TextEditingController();
    final TextEditingController parentCodeController = TextEditingController();

  String? ageGroup;
  String cvStatus = "pending"; // default value

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
                      //  controller: nameController,
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
                          //controller: emailController,
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
                        //controller: passwordController,
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
                         // controller: ageController,
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

                        // Age Group (auto-filled)
                       /*   TextFormField(
                          readOnly: true,
                          controller: TextEditingController(text: ageGroup ?? ""),
                          decoration: InputDecoration(
                            label: const Text("Age Group"),
                            prefixIcon: const Icon(Icons.category_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        */
                      ],

                      // Profile Picture (for all)
                      TextFormField(
                        //controller: profilePicController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter profile picture text";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          label: const Text("Profile Picture (text)"),
                          prefixIcon: const Icon(Icons.image_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // CV (supervisor only)
                      if (selectedRole == "supervisor") ...[
                        TextFormField(
                         // controller: cvController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your CV text";
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            label: const Text("CV (text)"),
                            prefixIcon: const Icon(Icons.description_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
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

                      // Parent Code (for parent only)
                      if (selectedRole == "parent") ...[
                        TextFormField(
                         // controller: parentCodeController,
                          readOnly: true,
                          decoration: InputDecoration(
                            label: const Text("Parent Code (Auto Generated)"),
                            prefixIcon: const Icon(Icons.qr_code),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              parentCodeController.text = "PARENT-${DateTime.now().millisecondsSinceEpoch}";
                            });
                          },
                          child: const Text("Generate Code"),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Account Created Successfully!")),
                              );
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
