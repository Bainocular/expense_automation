import 'dart:io';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:trial_exp_app/services/shared_pref_service.dart';

class DocumentCaptureScreen extends StatefulWidget {
  const DocumentCaptureScreen({Key? key}) : super(key: key);

  @override
  State<DocumentCaptureScreen> createState() => _DocumentCaptureScreenState();
}

class _DocumentCaptureScreenState extends State<DocumentCaptureScreen> {
  CameraController? _controller;
  List<XFile> capturedImages = [];
  bool isLastPageChecked = false;
  bool isCameraInitialized = false;
  bool _isSaving = false;
  bool _isEditing = false;

  final String saveApiUrl =
      "https://expense-tool-api-industrious-possum-lh.cfapps.us10-001.hana.ondemand.com/save-invoices";

  Map<String, dynamic>? _apiResponse;

  List<String> categories = [
    "Meal",
    "Transport",
    "Hotel",
    "Business",
    "Office expenses",
    "Telephone expenses",
    "Entertainment",
    "Other",
  ];
  String? _selectedCategory;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  // Future<void> uploadMultipleImages(List<XFile> images) async {
  Future<Map<String, dynamic>?> uploadMultipleImages(List<XFile> images) async {
    const String apiUrl =
        "https://expense-tool-api-industrious-possum-lh.cfapps.us10-001.hana.ondemand.com/read-invoices";

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    // Add multiple files
    for (var image in images) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'files', // MUST match FastAPI parameter name
          image.path,
        ),
      );
    }

    try {
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print("Upload success");
        print(responseBody);
        final decode = json.decode(responseBody);
        final invoice = decode['result'][0];

        setState(() {
          _apiResponse = invoice;
          _dateController.text = DateFormat(
            'MM/dd/yyyy',
          ).format(DateTime.parse(invoice['date']));

          _costController.text = invoice['discrepencyAmt'].toString();
          _categoryController.text = invoice['category'];
        });
        return jsonDecode(responseBody);
      } else {
        print("Upload failed");
        print(responseBody);
        return null;
      }
    } catch (e) {
      print("Error uploading images: $e");
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
      ).showSnackBar(const SnackBar(content: Text("Failing Saving")));
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;

    _controller = CameraController(camera, ResolutionPreset.medium);

    await _controller!.initialize();

    setState(() {
      isCameraInitialized = true;
    });
  }

  Future<void> _captureImage() async {
    if (!_controller!.value.isInitialized) return;

    final image = await _controller!.takePicture();

    setState(() {
      capturedImages.add(image);
    });
  }

  void _submitImages() async {
    if (capturedImages.isEmpty) return;

    // setState(() => isUploading = true);
    await uploadMultipleImages(capturedImages);
    // setState(() => isUploading = false);

    // var apiResponse = await uploadMultipleImages(capturedImages);
    // if (apiResponse != null) {
    //   _showEditDialog(apiResponse);
    // }
  }

  // void _showEditDialog(Map<String, dynamic> data) {
  //   TextEditingController dateController = TextEditingController(
  //     text: data["date"],
  //   );

  //   TextEditingController discrepencyController = TextEditingController(
  //     text: data["discrepencyAmt"].toString(),
  //   );

  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: const Text("Edit Invoice Details"),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             /// DATE
  //             TextField(
  //               controller: dateController,
  //               decoration: const InputDecoration(labelText: "Date"),
  //             ),

  //             const SizedBox(height: 10),

  //             /// DISCREPANCY AMOUNT
  //             TextField(
  //               controller: discrepencyController,
  //               keyboardType: TextInputType.number,
  //               decoration: const InputDecoration(
  //                 labelText: "Discrepancy Amount",
  //               ),
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () async {
  //               /// Modify API response
  //               data["date"] = dateController.text;
  //               data["discrepencyAmt"] =
  //                   double.tryParse(discrepencyController.text) ?? 0;

  //               await _saveInvoice(data);

  //               Navigator.pop(context);
  //             },
  //             child: const Text("Save"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // Future<void> _saveInvoice(Map<String, dynamic> invoice) async {
  //   const String apiUrl = "https://expense-tool-api-industrious-possum-lh.cfapps.us10-001.hana.ondemand.com/save-invoices";
  //   String? emailAddress = await PrefService.getEmail();

  //   Map<String, dynamic> body = {
  //     "user": emailAddress,
  //     "invoices": [invoice],
  //   };

  //   try {
  //     var response = await http.post(
  //       Uri.parse(apiUrl),
  //       headers: {"Content-Type": "application/json"},
  //       body: jsonEncode(body),
  //     );

  //     if (response.statusCode == 200) {
  //       ScaffoldMessenger.of(BuildContext).showSnackBar(
  //         const SnackBar(content: Text("Invoice saved successfully")),
  //       );
  //     } else {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text("Failed: ${response.body}")));
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text("Error: $e")));
  //   }
  // }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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

            Text(
              "Total Amount: \$${_apiResponse!['total_amount']}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _costController,
              enabled: _isEditing,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: "Cost (Discripency)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              // value: _selectedCategory,
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

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                });
              },
              child: Text(_isEditing ? "Done Editing" : "Edit"),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Document Capture"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Title
              const Text(
                "Capture Document Pages",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              /// Camera Preview Box
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade200,
                ),
                child: isCameraInitialized
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CameraPreview(_controller!),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),

              const SizedBox(height: 16),

              /// Capture Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: isLastPageChecked ? null : _captureImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Capture"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// Thumbnails Preview
              if (capturedImages.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: capturedImages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(capturedImages[index].path),
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 16),

              /// Checkbox
              Row(
                children: [
                  Checkbox(
                    value: isLastPageChecked,
                    onChanged: (value) {
                      setState(() {
                        isLastPageChecked = value!;
                      });
                    },
                  ),
                  const Text("This is the last page"),
                ],
              ),

              ElevatedButton(
                onPressed: isLastPageChecked && capturedImages.isNotEmpty
                    ? _submitImages
                    : null,
                child: const Text("Process"),
              ),

              //const Spacer(),
              const SizedBox(height: 16),

              _buildResponseSection(),

              const SizedBox(height: 16),

              /// Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      isLastPageChecked &&
                          capturedImages.isNotEmpty &&
                          !_isEditing &&
                          !_isSaving
                      ? _saveInvoice
                      : null,
                  child: const Text("Submit"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
