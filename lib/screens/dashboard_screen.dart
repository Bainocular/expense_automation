import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

//import '';
class DashboardSummary {
  final int totalEmployees;
  final int totalCustomers;
  final int totalClaims;
  final int pendingClaims;
  final int approvedClaims;
  final int rejectedClaims;
  final double totalClaimAmount;

  DashboardSummary({
    required this.totalEmployees,
    required this.totalCustomers,
    required this.totalClaims,
    required this.pendingClaims,
    required this.approvedClaims,
    required this.rejectedClaims,
    required this.totalClaimAmount,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalEmployees: json["total_employees"],
      totalCustomers: json["total_customers"],
      totalClaims: json["total_claims"],
      approvedClaims: json["approved_claims"],
      pendingClaims: json["pending_claims"],
      rejectedClaims: json["rejected_claims"],
      totalClaimAmount:
          double.tryParse(json["total_claim_amount"].toString()) ?? 0.0,
    );
  }
}

class RecentClaim {
  final String rid;
  final String employeeName;
  final String? customerName;
  final double amount;
  final String status;
  final String generatedAt;

  RecentClaim({
    required this.rid,
    required this.employeeName,
    this.customerName,
    required this.amount,
    required this.status,
    required this.generatedAt,
  });

  factory RecentClaim.fromJson(Map<String, dynamic> json) {
    return RecentClaim(
      rid: json["rid"],
      employeeName: json["employee_name"],
      customerName: json["customername"],
      amount: double.tryParse(json["user_claimed_amount"].toString()) ?? 0.0,
      status: json["status"],
      generatedAt: json["generated_at"].toString(),
    );
  }
}

class DashboardResponse {
  final DashboardSummary summary;
  final List<RecentClaim> recentClaims;

  DashboardResponse({required this.summary, required this.recentClaims});

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      summary: DashboardSummary.fromJson(json["summary"]),
      recentClaims: (json["recent_claims"] as List)
          .map((e) => RecentClaim.fromJson(e))
          .toList(),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsetsGeometry.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(.15),
              child: Icon(icon, color: color),
            ),

            const Spacer(),

            Text(title, style: Theme.of(context).textTheme.bodyMedium),

            const SizedBox(height: 5),

            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class RecentClaimTile extends StatelessWidget {
  final RecentClaim claim;

  const RecentClaimTile({super.key, required this.claim});

  Color getStatusColor() {
    switch (claim.status.toLowerCase()) {
      case "approved":
        return Colors.green;

      case "rejected":
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(claim.employeeName),
        subtitle: Text(claim.customerName ?? "N/A"),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${claim.amount.toStringAsFixed(0)}",
              style: TextStyle(color: getStatusColor()),
            ),

            Text(claim.status, style: TextStyle(color: getStatusColor())),
          ],
        ),

        onTap: () {
          //Navigate to claim Details Screen
        },
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = true;
  String? error;
  DashboardResponse? dashboard;

  Future<void> loadDashboard() async {
    const String baseUrl = "http://localhost:8008/dashboard";
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = DashboardResponse.fromJson(jsonDecode(response.body));

        setState(() {
          dashboard = data;
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
  void initState() {
    super.initState();
    loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Admin Dashboard")),
        body: Center(child: Text(error!)),
      );
    }

    final summary = dashboard!.summary;

    return Scaffold(
      appBar: AppBar(title: const Text("Expense Dashboard"), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: loadDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //SUMMARY CARDS
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  SummaryCard(
                    title: "Employees",
                    value: summary.totalEmployees.toString(),
                    icon: Icons.people,
                    color: Colors.blue,
                  ),

                  SummaryCard(
                    title: "Customers",
                    value: summary.totalCustomers.toString(),
                    icon: Icons.business,
                    color: Colors.orange,
                  ),

                  SummaryCard(
                    title: "Claims",
                    value: summary.totalClaims.toString(),
                    icon: Icons.receipt_long,
                    color: Colors.purple,
                  ),

                  SummaryCard(
                    title: "Amount",
                    value: summary.totalClaimAmount.toStringAsFixed(0),
                    icon: Icons.currency_exchange,
                    color: Colors.green,
                  ),

                  SummaryCard(
                    title: "Pending",
                    value: summary.pendingClaims.toString(),
                    icon: Icons.pending_actions,
                    color: Colors.amber,
                  ),

                  SummaryCard(
                    title: "Approved",
                    value: summary.approvedClaims.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),

                  SummaryCard(
                    title: "Rejected",
                    value: summary.rejectedClaims.toString(),
                    icon: Icons.cancel,
                    color: Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 25),

              Text(
                "Recent Claims",
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 10),
              ListView.builder(
                itemCount: dashboard!.recentClaims.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final claim = dashboard!.recentClaims[index];
                  return RecentClaimTile(claim: claim);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
