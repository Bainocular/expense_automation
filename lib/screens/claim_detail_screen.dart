import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:trial_exp_app/screens/user_invoices_list_screen.dart';
import 'package:trial_exp_app/screens/pdf_viewer_screen.dart';

class ClaimDetailModel {
  final String id;
  final String category;
  final String vendor;
  final double amount;
  final String filename;
  final String filePath;
  final DateTime? date;

  ClaimDetailModel({
    required this.id,
    required this.category,
    required this.vendor,
    required this.amount,
    required this.filename,
    required this.filePath,
    required this.date,
  });

  factory ClaimDetailModel.fromJson(Map<String, dynamic> json) {
    return ClaimDetailModel(
      id: json["id"] ?? "",
      category: json["category"] ?? "",
      vendor: json["vendor"] ?? "",
      amount: (json["totalamount"] as num?)?.toDouble() ?? 0.0,
      filename: json["filename"] ?? "",
      filePath: json["file_path"] ?? "",
      date: json["date"] != null ? DateTime.parse(json["date"]) : null,
    );
  }
}

class InvoiceCard extends StatelessWidget {
  final ClaimDetailModel invoice;
  final VoidCallback onView;

  const InvoiceCard({super.key, required this.invoice, required this.onView});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              invoice.category,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),

            Text("Vendor: ${invoice.vendor}"),

            const SizedBox(height: 8),

            Text(
              "₹ ${invoice.amount.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.visibility),
                label: const Text("View Invoice"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClaimDetailScreen extends StatefulWidget {
  final String reportId;

  const ClaimDetailScreen({super.key, required this.reportId});

  @override
  State<ClaimDetailScreen> createState() => _ClaimDetailScreenState();
}

class _ClaimDetailScreenState extends State<ClaimDetailScreen> {
  List<ClaimDetailModel> invoices = [];
  bool isLoading = true;
  Map<String, dynamic>? claim;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final String rid = (widget.reportId);
    final String claimDetailsUrl = "http://localhost:8008/claims/${rid}";

    try {
      final response = await http.get(Uri.parse(claimDetailsUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        final List<dynamic> invoicedata = data["invoices"] ?? [];

        print("Decoded Data: $data");
        print("Claim: ${data["claims"]}");
        print("Invoices: ${data["invoices"]}");

        setState(() {
          claim = data["claims"];
          invoices = invoicedata
              .map((e) => ClaimDetailModel.fromJson(e as Map<String, dynamic>))
              .toList();
          isLoading = false;
        });
      } else {
        print("Claim API failed: ${response.statusCode}");

        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget infoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(title, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return Colors.green;

      case "rejected":
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  void _showImage(BuildContext context, Uint8List bytes) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Future<void> _showPdf(
    BuildContext context,
    Uint8List bytes,
    String filename,
  ) async {
    final dir = await getTemporaryDirectory();
    final safeFileName = filename.split('/').last;

    final file = File('${dir.path}/$safeFileName');

    await file.writeAsBytes(bytes);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PdfViewerScreen(filePath: file.path)),
    );
  }

  Future<void> previewInvoice(BuildContext context, String filename) async {
    try {
      final response = await Dio().post(
        'http://localhost:8008/preview-invoice',
        data: {'filename': filename},
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = Uint8List.fromList(response.data);

      final ContentType = response.headers.value('content-type') ?? '';

      if (ContentType.contains('application/pdf')) {
        await _showPdf(context, bytes, filename);
      } else if (ContentType.startsWith('image/')) {
        _showImage(context, bytes);
      } else {
        throw Exception('Unsupported file type: $ContentType');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Preview failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (claim == null) {
      return const Scaffold(body: Center(child: Text("Unable to load claim")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Claim Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Claim #${claim!["rid"].toString().substring(0, 8)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Chip(
                      backgroundColor: getStatusColor(
                        claim!["status"],
                      ).withOpacity(.15),
                      label: Text(
                        claim!["status"],
                        style: TextStyle(
                          color: getStatusColor(claim!["status"]),
                        ),
                      ),
                    ),

                    const Divider(height: 30),

                    infoTile("Employee", claim!["employee_name"]),

                    infoTile("Customer", claim!["customername"]),

                    infoTile(
                      "Submitted",
                      DateFormat(
                        "dd MMM yyyy",
                      ).format(DateTime.parse(claim!["generated_at"])),
                    ),

                    infoTile("Amount", "₹ ${claim!["user_claimed_amount"]}"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Invoices",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            ...invoices.map(
              (invoice) => InvoiceCard(
                invoice: invoice,
                onView: () {
                  /// reuse your existing preview screen
                  previewInvoice(context, invoice.filename);
                },
              ),
            ),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},

                    icon: const Icon(Icons.check),

                    label: const Text("Approve"),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},

                    icon: const Icon(Icons.close),

                    label: const Text("Reject"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {},

                icon: const Icon(Icons.reply),

                label: const Text("Send Back"),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
