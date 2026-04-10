import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:trial_exp_app/services/shared_pref_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';

class GenerateReportScreen extends StatefulWidget {
  const GenerateReportScreen({super.key});

  @override
  State<GenerateReportScreen> createState() => _GenerateReportScreenState();
}

class _GenerateReportScreenState extends State<GenerateReportScreen> {
  DateTime? fromDate;
  DateTime? toDate;
  bool isLoading = false;

  final DateFormat formatter = DateFormat('MM/dd/yyyy');
  final DateFormat displyformat = DateFormat('yyyy-MM-dd');
  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  Future<void> _generateReport() async {
    if (fromDate == null || toDate == null) {
      _showDialog("Missing Dates", "Please select both dates.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // final prefs = await SharedPreferences.getInstance();
      // final email = prefs.getString('email') ?? "";
      String? email = await PrefService.getEmail();
      String? client = await PrefService.getClient();

      final response = await http.post(
        Uri.parse(
          "https://default63448fe632a44c6eb69a0dbd1eb573.00.environment.api.powerplatform.com:443/powerautomate/automations/direct/workflows/2cd29a2fde964ba79747ca4db17effcc/triggers/manual/paths/invoke?api-version=1&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=VQlesEr65NaK9Cx3xhq7mUtCP87HjOxB4lBwN7TyuIc",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user": email,
          "customer": client,
          "from_date": displyformat.format(fromDate!),
          "to_date": displyformat.format(toDate!),
        }),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showDialog("Success", "Report generated successfully.");
      } else {
        _showDialog("Error", "Failed to generate report.");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showDialog("Error", e.toString());
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _dateSelector(String label, DateTime? date, bool isFrom) {
    return InkWell(
      onTap: () => _pickDate(context, isFrom),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date == null ? label : formatter.format(date),
              style: const TextStyle(fontSize: 16),
            ),
            const Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Generate Report"), centerTitle: true),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Generate Your Report",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Text(
                  "Select a date range to generate the report.",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),

                const SizedBox(height: 32),

                _dateSelector("Select From Date", fromDate, true),

                const SizedBox(height: 16),

                _dateSelector("Select To Date", toDate, false),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _generateReport,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Generate Report",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
