import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../screens/claim_detail_screen.dart';

class ClaimModel {
  final String rid;
  final String employeeId;
  final String employeeName;
  final String customerName;
  final double amount;
  final String status;
  final DateTime generatedAt;

  ClaimModel({
    required this.rid,
    required this.employeeId,
    required this.employeeName,
    required this.customerName,
    required this.amount,
    required this.status,
    required this.generatedAt,
  });

  factory ClaimModel.fromJson(Map<String, dynamic> json) {
    return ClaimModel(
      rid: json["rid"],
      employeeId: json["employee_id"] ?? "",
      employeeName: json["employee_name"] ?? "",
      customerName: json["customername"] ?? "",
      amount: (json["user_claimed_amount"] as num?)?.toDouble() ?? 0.0,
      status: json["status"] ?? "",
      generatedAt: DateTime.parse(json["generated_at"]),
    );
  }
}

class ClaimCard extends StatelessWidget {
  final ClaimModel claim;
  final VoidCallback onTap;

  const ClaimCard({super.key, required this.claim, required this.onTap});

  Color statusColor() {
    switch (claim.status.toLowerCase()) {
      case "approved":
        return Colors.green;

      case "rejected":
        return Colors.orange;

      case "pending":
        return Colors.orange;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.person)),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      claim.employeeName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Chip(
                    backgroundColor: statusColor().withOpacity(.15),
                    label: Text(
                      claim.status,
                      style: TextStyle(
                        color: statusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  const Icon(Icons.business, size: 18),

                  const SizedBox(width: 8),

                  Text(claim.customerName),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),

                  const SizedBox(width: 8),

                  Text(DateFormat("dd MMM yyyy").format(claim.generatedAt)),
                ],
              ),

              const Divider(height: 30),

              const Text("Claim Amount", style: TextStyle(color: Colors.grey)),

              const SizedBox(height: 5),

              Text(
                "₹ ${claim.amount.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Divider(height: 30),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text("View Details"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClaimsScreen extends StatefulWidget {
  const ClaimsScreen({super.key});

  @override
  State<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends State<ClaimsScreen> {
  List<ClaimModel> claims = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadClaims();
  }

  Future<void> loadClaims() async {
    const String claimsUrl = "http://localhost:8008/claims";

    try {
      final response = await http.get(
        Uri.parse(claimsUrl),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        //final data = jsonDecode(response.body);
        final Map<String, dynamic> json = jsonDecode(response.body);

        final List<dynamic> data = json["claims_summary"];

        setState(() {
          claims = data.map((e) => ClaimModel.fromJson(e)).toList();
          isLoading = false;
        });
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
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: claims.length,
      itemBuilder: (context, index) {
        return ClaimCard(
          claim: claims[index],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ClaimDetailScreen(reportId: claims[index].rid),
              ),
            );
          },
        );
      },
    );
  }
}
