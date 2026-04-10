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

  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  bool _isLoading = false;
  bool _showOtpField = false;
  String? _serverOtp;

  final String apiUrl =
      "https://invoice-reimbursement-backend.cfapps.us10-001.hana.ondemand.com/api/v1/invoice-validation/flutter/user/login";

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
          _showOtpField = true;
        });
      } else if (response.statusCode == 400) {
        _showDialog("Error", response.body);
      }
    } catch (e) {
      _showDialog("Error", "Something went wrong");
    }

    setState(() => _isLoading = false);
  }

  void validateOtp() async {
    String enteredOtp = _otpControllers.map((c) => c.text).join();
    String? selectedClient;

    if (enteredOtp == _serverOtp) {
      // _showDialog("Success", "OTP Verified Successfully!");
      // await saveEmail(_emailController.text.trim());
      await PrefService.saveEmail(_emailController.text.trim());

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
                const Text("OTP Successful!"),
                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: dropdownValue,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Select Client",
                  ),
                  items: const [
                    DropdownMenuItem(value: "Monster Energy", child: Text("Monster Energy")),
                    DropdownMenuItem(value: "Jacklinks", child: Text("Jacklinks")),
                    DropdownMenuItem(value: "Luxottica", child: Text("Luxottica")),
                    DropdownMenuItem(value: "Public Storage", child: Text("Public Storage")),
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
                style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 74, 74, 74)),
              ),
              const SizedBox(height: 10),

              /// Email Field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "Email Address",
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
                    : const Text("Send OTP"),
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
