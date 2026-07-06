import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:trial_exp_app/screens/pdf_viewer_screen.dart';
import 'package:trial_exp_app/services/shared_pref_service.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';

class User {
  final String filename;
  final DateTime date;
  final String category;
  final String vendor;
  final double total_amount;
  final String? filepath;

  User({
    required this.filename,
    required this.date,
    required this.category,
    required this.vendor,
    required this.total_amount,
    this.filepath,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      filename: json['filename'],
      date: DateTime.parse(json['date']),
      category: json['category'],
      vendor: json['vendor'],
      total_amount: json['total_amount'],
      filepath: json['filepath'],
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
  String? selectedCategory;
  DateTime? fromDate;
  DateTime? toDate;
  double? minAmount;
  double? maxAmount;
  List<User> filteredInvoices = [];
  //List<>

  final minAmountController = TextEditingController();
  final maxAmountController = TextEditingController();

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
          filteredInvoices = users;
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

  void applyFilters() {
    setState(() {
      filteredInvoices = users.where((invoice) {
        final categoryMatch =
            selectedCategory == null || invoice.category == selectedCategory;

        final fromDateMatch =
            fromDate == null || !invoice.date.isBefore(fromDate!);

        final toDateMatch = toDate == null || !invoice.date.isAfter(toDate!);

        final minAmountMatch =
            minAmount == null || invoice.total_amount >= minAmount!;

        final maxAmountMatch =
            maxAmount == null || invoice.total_amount <= maxAmount!;

        return categoryMatch &&
            fromDateMatch &&
            toDateMatch &&
            minAmountMatch &&
            maxAmountMatch;
      }).toList();
    });
  }

  void showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //category
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Category'),
                      value: selectedCategory,
                      items:
                          [
                                "Meal",
                                "Transport",
                                "Hotel",
                                "Business",
                                "Office expenses",
                                "Telephone expenses",
                                "Entertainment",
                                "Other",
                              ]
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedCategory = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    ListTile(
                      title: Text(
                        fromDate == null
                            ? 'From Date'
                            : fromDate!.toString().split(' ')[0],
                      ),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          initialDate: fromDate ?? DateTime.now(),
                        );
                        if (picked != null) {
                          setModalState(() {
                            fromDate = picked;
                          });
                        }
                      },
                    ),

                    //To Date
                    ListTile(
                      title: Text(
                        toDate == null
                            ? 'To Date'
                            : toDate!.toString().split(' ')[0],
                      ),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          initialDate: toDate ?? DateTime.now(),
                        );

                        if (picked != null) {
                          setModalState(() {
                            toDate = picked;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: minAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Min Amount',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: maxAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max Amount',
                      ),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        minAmount = double.tryParse(minAmountController.text);
                        maxAmount = double.tryParse(maxAmountController.text);

                        applyFilters();
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),

                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedCategory = null;
                          fromDate = null;
                          toDate = null;
                          minAmount = null;
                          maxAmount = null;

                          filteredInvoices = List.from(users);
                        });

                        Navigator.pop(context);
                      },
                      child: const Text('Clear Filters'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void previewDocument(BuildContext context, String filePath) {
    final extension = filePath.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png'].contains(extension)) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          child: InteractiveViewer(
            child: Image.file(File(filePath), fit: BoxFit.contain),
          ),
        ),
      );
    } else if (extension == 'pdf') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PdfViewerScreen(filePath: filePath)),
      );
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
        'https://expense-tool-api-industrious-possum-lh.cfapps.us10-001.hana.ondemand.com/preview-invoice',
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: Theme.of(context).iconTheme.size,
            color: Theme.of(context).iconTheme.color,
          ),
          const SizedBox(width: 10),
          Text("$label: ", style: Theme.of(context).textTheme.bodyMedium),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices '),
        actions: [
          IconButton(
            onPressed: () {
              showFilterSheet();
            },
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
          ? const Center(child: Text('No Data Found'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              //itemCount: users.length,
              itemCount: filteredInvoices.length,
              itemBuilder: (context, index) {
                //final user = users[index];
                final user = filteredInvoices[index];

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                user.filename,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium /*const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),*/,
                              ),
                            ),

                            IconButton(
                              onPressed: user.filepath == null
                                  ? null
                                  : () async {
                                      await previewInvoice(
                                        context,
                                        user.filepath!,
                                      );
                                    },
                              icon: Icon(
                                Icons.visibility,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              tooltip: 'Preview',
                            ),
                          ],
                        ),
                        const Divider(height: 20),

                        _buildInfoRow(
                          Icons.calendar_today,
                          "Date",
                          DateFormat('MM//dd/yyyy').format(user.date),
                        ),
                        _buildInfoRow(
                          Icons.category,
                          "Category",
                          user.category,
                        ),
                        _buildInfoRow(Icons.business, "Vendor", user.vendor),
                        _buildInfoRow(
                          Icons.currency_rupee,
                          "Amount",
                          "₹ ${user.total_amount}",
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      /* : SingleChildScrollView(
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
            ),*/
    );
  }
}
