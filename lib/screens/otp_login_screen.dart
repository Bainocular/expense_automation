import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:trial_exp_app/screens/home_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart';

import 'package:trial_exp_app/screens/trial_homepage.dart';
import 'package:trial_exp_app/services/shared_pref_service.dart';

class OTPLoginScreen extends StatefulWidget {
  const OTPLoginScreen({Key? key}) : super(key: key);

  @override
  State<OTPLoginScreen> createState() => _OTPLoginScreenState();
}

class _OTPLoginScreenState extends State<OTPLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  bool _isLoading = false;
  bool _showOtpField = false;
  String? _serverOtp;
  String _selectedUserRole = 'Consultant';

  final String apiUrl =
      "https://expense-tool-api-industrious-possum-lh.cfapps.us10-001.hana.ondemand.com/authenticate-user";

  final String registerUserUrl =
      "https://expense-tool-api-industrious-possum-lh.cfapps.us10-001.hana.ondemand.com/register-user";
  // Email Regex
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Future<void> saveEmail(String email) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString('user_email', email);
  // }

  Future<void> submitEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email-id": _emailController.text.trim()}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _serverOtp = data["otp"].toString();
          _nameController.text = data["name"];
          _showOtpField = true;
        });
      } else if (response.statusCode == 400) {
        _showDialog("Error", response.body);
      }
    } catch (e) {
      print("Error: ${e}");
      _showDialog("Error", "Something went wrong");
    }

    setState(() => _isLoading = false);
  }

  Future<void> addUser(name, email) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(registerUserUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode([
          {
            "name": name.trim(),
            "username": email.trim(),
            "role": _selectedUserRole,
          },
        ]),
      );

      print(response.statusCode);
      print(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registered Successfully")),
        );

        setState(() {
          _selectedUserRole = 'Consultant';
        });
      } else {
        print("Not Successfull");
        print(response.body);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.body)));
      }
    } catch (e) {
      print("Error");
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void validateOtp() async {
    String enteredOtp = _otpControllers.map((c) => c.text).join();
    String? selectedClient;

    if (enteredOtp == _serverOtp) {
      // _showDialog("Success", "OTP Verified Successfully!");
      // await saveEmail(_emailController.text.trim());
      await PrefService.saveEmail(_emailController.text.trim());
      final data;
      //final user;
      dynamic user;
      final userDataUrl = Uri.parse(
        "https://expense-tool-api-industrious-possum-lh.cfapps.us10-001.hana.ondemand.com/get-users",
      );

      final response = await http.post(
        userDataUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user': _emailController.text.trim()}),
      );
      print("Response status: ${response.statusCode}");
      print('user data in db: ${jsonDecode(response.body)}');
      if (response.statusCode == 200) {
        data = jsonDecode(response.body);
        if (data['result'] != null) {
          user = data['result'];
        } else if (data['error'] != null) {
          user = null;
        }
      } else {
        print('API Error: ${response.statusCode}');
        print(response.body);
        user = null;
      }

      if (user != null) {
        print("Inside user not equal to null : ${user}");
        await PrefService.saveRole(user[5]);
      } else if (user == null) {
        print("Inside user equal to null : ${user}");
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: /*const*/ Text(
              "Message",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedUserRole,
                  style: Theme.of(context).textTheme.bodyMedium,
                  dropdownColor: Theme.of(context).cardColor,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      [
                            'Admin',
                            'Consultant',
                            'G&A',
                            'Sales',
                            'Technical/Functional',
                          ]
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(
                                role,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedUserRole = value!;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  //addUser(user[1], user[2]);
                  addUser(
                    _nameController.text.trim(),
                    _emailController.text.trim(),
                  );

                  Navigator.pop(context);

                  showDialog(
                    context: context,
                    builder: (context) {
                      String? dropdownValue = "Monster Energy"; // default value

                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: const Text("Success"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "OTP Successful!",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),

                            DropdownButtonFormField<String>(
                              value: dropdownValue,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "Select Client",
                                labelStyle: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: "Monster Energy",
                                  child: Text("Monster Energy"),
                                ),
                                DropdownMenuItem(
                                  value: "Jacklinks",
                                  child: Text("Jacklinks"),
                                ),
                                DropdownMenuItem(
                                  value: "Luxottica",
                                  child: Text("Luxottica"),
                                ),
                                DropdownMenuItem(
                                  value: "Public Storage",
                                  child: Text("Public Storage"),
                                ),
                                DropdownMenuItem(
                                  value: "SELECCION Internal",
                                  child: Text("SELECCION Internal"),
                                ),
                              ],
                              onChanged: (value) {
                                dropdownValue = value;
                              },
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () async {
                              await PrefService.saveClient(dropdownValue);

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HomeScreen(),
                                ),
                              );
                            },
                            child: const Text("OK"),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text("Register"),
              ),
            ],
          ),
        );

        return;
      }
      // showDialog(
      //   context: context,
      //   builder: (_) => AlertDialog(
      //     shape: RoundedRectangleBorder(
      //       borderRadius: BorderRadius.circular(12),
      //     ),
      //     title: Text("Success"),
      //     content: Text("OTP Successful!"),
      //     actions: [
      //       TextButton(
      //         onPressed: () => {
      //           Navigator.pushReplacement(
      //             context,
      //             MaterialPageRoute(builder: (context) => TrialHomepage()),
      //           ),
      //         },
      //         child: const Text("OK"),
      //       ),
      //     ],
      //   ),
      // );
      showDialog(
        context: context,
        builder: (context) {
          String? dropdownValue = "Monster Energy"; // default value

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text("Success"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "OTP Successful!",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: dropdownValue,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Select Client",
                    labelStyle: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: "Monster Energy",
                      child: Text("Monster Energy"),
                    ),
                    DropdownMenuItem(
                      value: "Jacklinks",
                      child: Text("Jacklinks"),
                    ),
                    DropdownMenuItem(
                      value: "Luxottica",
                      child: Text("Luxottica"),
                    ),
                    DropdownMenuItem(
                      value: "Public Storage",
                      child: Text("Public Storage"),
                    ),
                    DropdownMenuItem(
                      value: "SELECCION Internal",
                      child: Text("SELECCION Internal"),
                    ),
                  ],
                  onChanged: (value) {
                    dropdownValue = value;
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await PrefService.saveClient(dropdownValue);

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    } else {
      _showDialog("Error", "Incorrect OTP entered");
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget buildOtpFields() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          "Enter OTP",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 45,
              child: TextField(
                controller: _otpControllers[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: const Color.fromARGB(255, 130, 212, 247),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    FocusScope.of(context).nextFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: validateOtp,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("Verify OTP"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                "Welcome to SELECCION 👋",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              const Text(
                "Enter your email to continue",
                style: TextStyle(
                  fontSize: 16,
                  //color: Color.fromARGB(255, 74, 74, 74),
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              /// Email Field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "Email Address",
                  hintStyle: TextStyle(
                    //fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 130, 212, 247),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Email required";
                  } else if (!isValidEmail(value)) {
                    return "Enter valid email";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              /// Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : submitEmail,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Send OTP",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),

              const SizedBox(height: 30),

              /// OTP Section
              if (_showOtpField) buildOtpFields(),
            ],
          ),
        ),
      ),
    );
  }
}
