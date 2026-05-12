import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ConfigureMilesScreen extends StatefulWidget {
  const ConfigureMilesScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ConfigureMilesScreenState();
}

class _ConfigureMilesScreenState extends State<ConfigureMilesScreen> {
  final TextEditingController costmileController = TextEditingController();
  DateTime? fromDate;
  DateTime? toDate;

  final String apiUrl =
      "https://expense-tool-api-industrious-possum-lh.cfapps.us10-001.hana.ondemand.com/configure-miles";

  final DateFormat requestDateFormat = DateFormat('yyyy-MM-dd');

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

  Future<void> _configureMiles() async {
    if (fromDate == null || toDate == null) {
      _showDialog("Missing Dates", "Please select dates");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "cost": double.parse(costmileController.text),
          "from_date": DateFormat('yyyy-MM-dd').format(fromDate!),
          "to_date": DateFormat('yyyy-MM-dd').format(toDate!),
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showDialog("Success", "Configured cost per mile successfully");
      } else {
        _showDialog("Error", "Sorry! Something went wrong");
      }
    } catch (e) {
      _showDialog("Error", e.toString());
    }
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
              date == null ? label : DateFormat('MM/dd/yyyy').format(date),
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
      appBar: AppBar(
        title: const Text("Configure Track Miles"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /*const*/ Text(
                  "Configure Cost Per Mile",
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                const SizedBox(height: 8),

                Text(
                  "Cost (per mile)",
                  style: Theme.of(context).textTheme.titleMedium,
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: costmileController,
                  //enabled: _isEditing,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: "Enter cost per mile",
                    labelStyle: Theme.of(context).textTheme.bodyMedium,
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  "Select Date Range",
                  style: Theme.of(context).textTheme.titleMedium,
                ),

                const SizedBox(height: 32),

                _dateSelector("From Date", fromDate, true),

                const SizedBox(height: 16),

                _dateSelector("To Date", toDate, false),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _configureMiles,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Configure",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
