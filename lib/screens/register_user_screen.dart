import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:trial_exp_app/services/url_params.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({Key? key}) : super(key: key);

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  String selectedRole = 'Consultant';

  bool isLoading = false;

  //Replace with your API URL
  final String apiUrl = ApiUrl.registerUserUrl;
      //"http://34.63.210.75:3006/register-user";

  Future<void> addUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode([
          {
            "name": nameController.text.trim(),
            "username": emailController.text.trim(),
            "role": selectedRole,
          },
        ]),
      );

      print(response.statusCode);
      print(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User Added Successfully")),
        );

        nameController.clear();
        emailController.clear();

        setState(() {
          selectedRole = 'Consultant';
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

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add User')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Employee Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter name";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter Email';
                  }

                  if (!value.contains('@')) {
                    return 'Enter valid emailaddress';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedRole,
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
                    selectedRole = value!;
                  });
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : addUser,
                  style: Theme.of(context).elevatedButtonTheme.style,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Add User'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
