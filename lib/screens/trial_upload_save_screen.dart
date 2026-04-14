// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';

// class UploadInvoiceScreen extends StatefulWidget {
//   const UploadInvoiceScreen({Key? key}) : super(key: key);

//   @override
//   State<UploadInvoiceScreen> createState() => _UploadInvoiceScreenState();
// }

// class _UploadInvoiceScreenState extends State<UploadInvoiceScreen> {
//   File? _selectedFile;
//   bool _isLoading = false;
//   Map<String, dynamic>? _apiResponse;
//   bool _isEditing = false;

//   final TextEditingController _dateController = TextEditingController();
//   final TextEditingController _costController = TextEditingController();

//   final String uploadApiUrl = "https://expense-tool-api-industrious-possum-lh.cfapps.us10-001.hana.ondemand.com/read-invoices";
//   final String saveApiUrl = "https://expense-tool-api-industrious-possum-lh.cfapps.us10-001.hana.ondemand.com/save-invoices";

//   Future<void> _pickFile() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
//     );

//     if (result != null) {
//       setState(() {
//         _selectedFile = File(result.files.single.path!);
//         _apiResponse = null;
//       });
//     }
//   }

//   Future<void> _processFile() async {
//     if (_selectedFile == null) return;

//     setState(() => _isLoading = true);

//     var request = http.MultipartRequest('POST', Uri.parse(uploadApiUrl));

//     request.files.add(
//       await http.MultipartFile.fromPath('files', _selectedFile!.path),
//     );

//     var response = await request.send();
//     var responseBody = await response.stream.bytesToString();

//     setState(() {
//       _isLoading = false;
//     });

//     if (response.statusCode == 200) {
//       final decoded = json.decode(responseBody);
//       final invoice = decoded['result'][0];

//       setState(() {
//         _apiResponse = invoice;
//         _dateController.text = invoice['date'];
//         _costController.text = invoice['discrepencyAmt'].toString();
//       });
//     } else {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Upload Failed")));
//     }
//   }

//   Future<void> _saveInvoice() async {
//     if (_apiResponse == null) return;

//     final updatedInvoice = Map<String, dynamic>.from(_apiResponse!);

//     updatedInvoice['date'] = _dateController.text;
//     updatedInvoice['discrepencyAmt'] =
//         double.tryParse(_costController.text) ?? 0;

//     final body = {
//       "user": "harshith.kandula@seleccionconsulting.com",
//       "invoices": [updatedInvoice],
//     };

//     final response = await http.post(
//       Uri.parse(saveApiUrl),
//       headers: {"Content-Type": "application/json"},
//       body: json.encode(body),
//     );

//     if (response.statusCode == 200) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Saved Successfully")));
//     } else {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Save Failed")));
//     }
//   }

//   Widget _buildPreview() {
//     if (_selectedFile == null) return const SizedBox();

//     if (_selectedFile!.path.endsWith(".pdf")) {
//       return const Icon(Icons.picture_as_pdf, size: 100, color: Colors.red);
//     } else {
//       return Image.file(_selectedFile!, height: 150);
//     }
//   }

//   Widget _buildResponseSection() {
//     if (_apiResponse == null) return const SizedBox();

//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.symmetric(vertical: 20),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _buildTextField("Date", _dateController, enabled: _isEditing),
//             const SizedBox(height: 12),
//             Text(
//               "Total Amount: \$${_apiResponse!['total_amount']}",
//               style: const TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 12),
//             _buildTextField(
//               "Cost (Discrepency)",
//               _costController,
//               enabled: _isEditing,
//               isNumeric: true,
//             ),
//             const SizedBox(height: 20),
//             if (!_isEditing)
//               ElevatedButton(
//                 onPressed: () => setState(() => _isEditing = true),
//                 child: const Text("Edit"),
//               ),
//             if (_isEditing)
//               ElevatedButton(
//                 onPressed: () => setState(() => _isEditing = false),
//                 child: const Text("Done Editing"),
//               ),
//             const SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: _saveInvoice,
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//               child: const Text("Save"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField(
//     String label,
//     TextEditingController controller, {
//     bool enabled = false,
//     bool isNumeric = false,
//   }) {
//     return TextField(
//       controller: controller,
//       enabled: enabled,
//       keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Upload Invoice"), centerTitle: true),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             const Text(
//               "Upload JPG, PNG or PDF",
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _pickFile,
//               child: const Text("Select File"),
//             ),
//             const SizedBox(height: 20),
//             _buildPreview(),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _isLoading ? null : _processFile,
//               child: _isLoading
//                   ? const CircularProgressIndicator()
//                   : const Text("Process"),
//             ),
//             _buildResponseSection(),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:trial_exp_app/services/shared_pref_service.dart';

class UploadInvoiceScreen extends StatefulWidget {
  const UploadInvoiceScreen({Key? key}) : super(key: key);

  @override
  State<UploadInvoiceScreen> createState() => _UploadInvoiceScreenState();
}

class _UploadInvoiceScreenState extends State<UploadInvoiceScreen> {
  File? _selectedFile;
  bool _isProcessing = false;
  bool _isSaving = false;
  bool _isEditing = false;

  Map<String, dynamic>? _apiResponse;

  List<String> categories = ["Meal", "Transport", "Hotel", "Business", "Other"];

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  final String uploadApiUrl =
      "https://expense-tool-api-industrious-possum-lh.cfapps.us10-001.hana.ondemand.com/read-invoices";
  final String saveApiUrl =
      "https://expense-tool-api-industrious-possum-lh.cfapps.us10-001.hana.ondemand.com/save-invoices";
  String? _selectedCategory;

  /// PICK FILE
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _apiResponse = null;
      });
    }
  }

  /// PROCESS FILE (UPLOAD)
  Future<void> _processFile() async {
    if (_selectedFile == null) return;

    setState(() => _isProcessing = true);

    var request = http.MultipartRequest('POST', Uri.parse(uploadApiUrl));

    request.files.add(
      await http.MultipartFile.fromPath('files', _selectedFile!.path),
    );

    print(request.files);

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    setState(() => _isProcessing = false);

    if (response.statusCode == 200) {
      final decoded = json.decode(responseBody);
      final invoice = decoded['result'][0];

      setState(() {
        _apiResponse = invoice;
        _dateController.text = DateFormat(
          'MM/dd/yyyy',
        ).format(DateTime.parse(invoice['date']));
        _costController.text = invoice['discrepencyAmt'].toString();
        _categoryController.text = invoice['category'];
      });
    }
  }

  /// DATE PICKER
  Future<void> _selectDate() async {
    DateTime initialDate =
        DateTime.tryParse(_dateController.text) ?? DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  /// SAVE API
  Future<void> _saveInvoice() async {
    if (_apiResponse == null) return;

    setState(() => _isSaving = true);

    final updatedInvoice = Map<String, dynamic>.from(_apiResponse!);
    String? email_address = await PrefService.getEmail();
    String? client_name = await PrefService.getClient();

    updatedInvoice['date'] = _dateController.text;
    updatedInvoice['discrepencyAmt'] =
        double.tryParse(_costController.text) ?? 0;
    updatedInvoice['category'] = _categoryController.text;
    final body = {
      "user": email_address,
      "force_save": "false",
      "customer": client_name,
      "invoices": [updatedInvoice],
    };

    final response = await http.post(
      Uri.parse(saveApiUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );

    setState(() => _isSaving = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Saved Successfully")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Save Failed")));
    }
  }

  Widget _buildPreview() {
    if (_selectedFile == null) return const SizedBox();

    if (_selectedFile!.path.endsWith(".pdf")) {
      return const Icon(Icons.picture_as_pdf, size: 100, color: Colors.red);
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(_selectedFile!, height: 150),
      );
    }
  }

  Widget _buildResponseSection() {
    if (_apiResponse == null) return const SizedBox();

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// DATE FIELD (Date Picker Only)
            TextField(
              controller: _dateController,
              readOnly: true,
              onTap: _isEditing ? _selectDate : null,
              decoration: InputDecoration(
                labelText: "Date",
                suffixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// TOTAL AMOUNT
            Text(
              "Total Amount: \$${_apiResponse!['total_amount']}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 12),

            /// COST FIELD
            TextField(
              controller: _costController,
              enabled: _isEditing,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: "Cost (Discrepency)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              //value: _selectedCategory,
              initialValue: _categoryController.text,
              decoration: InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
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
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
              onChanged: _isEditing
                  ? (value) {
                      setState(() {
                        _selectedCategory = value;
                        _categoryController.text = value ?? "";
                      });
                    }
                  : null,
            ),

            /// EDIT / DONE BUTTON
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                });
              },
              child: Text(_isEditing ? "Done Editing" : "Edit"),
            ),

            const SizedBox(height: 10),

            /// SAVE BUTTON (Disabled while editing)
            ElevatedButton(
              onPressed: (!_isEditing && !_isSaving) ? _saveInvoice : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Invoice"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Upload JPG, PNG or PDF",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _pickFile,
              child: const Text("Select File"),
            ),

            const SizedBox(height: 20),
            _buildPreview(),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isProcessing ? null : _processFile,
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Process"),
            ),

            _buildResponseSection(),
          ],
        ),
      ),
    );
  }
}
