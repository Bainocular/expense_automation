import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:trial_exp_app/services/shared_pref_service.dart';

class User {
  final String filename;
  final DateTime date;
  final String category;
  final String vendor;
  final double total_amount;

  User({
    required this.filename,
    required this.date,
    required this.category,
    required this.vendor,
    required this.total_amount,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      filename: json['filename'],
      date: DateTime.parse(json['date']),
      category: json['category'],
      vendor: json['vendor'],
      total_amount: json['total_amount'],
    );
  }
}

class UserInvoicesListScreen extends StatefulWidget {
  const UserInvoicesListScreen({super.key});

  @override
  State<UserInvoicesListScreen> createState() => _UserInvoicesListState();
}

class _UserInvoicesListState extends State<UserInvoicesListScreen> {
  bool isLoading = true;
  String? username = "";
  List<User> users = [];

  //List<>

  void initState() {
    super.initState();
    loadPrefs();
    fetchUsers();
  }

  loadPrefs() async {
    String? email = await PrefService.getEmail();

    setState(() {
      username = email;
    });
  }

  Future<void> fetchUsers() async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://expense-tool-api-industrious-possum-lh.cfapps.us10-001.hana.ondemand.com/fetch-user-invoices',
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user": await PrefService.getEmail()}),
      );

      if (response.statusCode == 200) {
        //final List<dynamic> data = jsonDecode(response.body);
        final data = jsonDecode(response.body);
        print('User invoices data fetched: ${data}');
        setState(() {
          //users = data['response'].map((e) => User.fromJson(e)).toList();
          users = (data['response'] as List)
              .map((item) => User.fromJson(item))
              .toList();
          print('User class invoices: ${users}');
          isLoading = false;
        });
      } else if (response.statusCode == 400) {
        print("Error: ${response.body}");
      }
    } catch (e) {
      print("Error: ${e}");
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoices ')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
          ? const Center(child: Text('No Data Found'))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    Colors.blue.shade100,
                  ),
                  columns: const [
                    DataColumn(label: Text('Filename')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Category')),
                    DataColumn(label: Text('Vendor')),
                    DataColumn(label: Text('Total Amount')),
                  ],
                  rows: users.map((user) {
                    return DataRow(
                      cells: [
                        DataCell(Text(user.filename)),
                        DataCell(
                          Text(DateFormat('MM/dd/yyyy').format(user.date)),
                        ),
                        DataCell(Text(user.category)),
                        DataCell(Text(user.vendor)),
                        DataCell(Text(user.total_amount.toString())),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }
}
