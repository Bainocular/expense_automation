import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:trial_exp_app/services/shared_pref_service.dart';

class MilesScreen extends StatefulWidget {
  const MilesScreen({super.key});

  @override
  State<MilesScreen> createState() => _MilesScreenState();
}

class _MilesScreenState extends State<MilesScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime selectedDate = DateTime.now();
  final TextEditingController milesController = TextEditingController();

  bool isLoading = false;

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2022),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> processAPI() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      // String email = prefs.getString('email') ?? "";
      String? email = await PrefService.getEmail();
      String? client = await PrefService.getClient();

      var body = {
        "user": email,
        "date": DateFormat('yyyy-MM-dd').format(selectedDate),
        "miles": double.parse(milesController.text),
        "customer": client
      };

      print(body);
      print(client);

      final response = await http.post(
        Uri.parse("https://expense-tool-api-industrious-possum-lh.cfapps.us10-001.hana.ondemand.com/cost-miles"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print(response.body);

      setState(() {
        isLoading = false;
      });

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Response"),
          content: Text(response.body),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mileage Processor"),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                radius: 1.2,
                center: Alignment.topLeft,
                colors: [
                  Color(0xff4facfe),
                  Color(0xff00f2fe),
                ],
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: Card(
                elevation: 10,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        const Text(
                          "Submit Miles",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          "Enter date and miles to process",
                          style: TextStyle(color: Colors.grey),
                        ),

                        const SizedBox(height: 30),

                        // DATE FIELD
                        InkWell(
                          onTap: pickDate,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: "Date",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('yyyy-MM-dd')
                                      .format(selectedDate),
                                ),
                                const Icon(Icons.calendar_today)
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // MILES FIELD
                        TextFormField(
                          controller: milesController,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          decoration: InputDecoration(
                            labelText: "Miles",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Enter miles";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: processAPI,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Process",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
        ],
      ),
    );
  }
}