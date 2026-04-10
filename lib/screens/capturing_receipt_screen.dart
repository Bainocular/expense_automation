import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class InvoiceCameraScreen extends StatefulWidget {
  const InvoiceCameraScreen({super.key});

  @override
  State<InvoiceCameraScreen> createState() => _InvoiceCameraScreenState();
}

class _InvoiceCameraScreenState extends State<InvoiceCameraScreen> {
  CameraController? controller;

  List<XFile> images = [];
  bool isLastPage = false;

  bool processing = false;
  bool saving = false;

  List<dynamic> apiResponse = [];

  final dateController = TextEditingController();
  final discrepencyController = TextEditingController();

  final String processApi = "https://expense-tool-api-industrious-possum-lh.cfapps.us10-001.hana.ondemand.com/read-invoices";
  final String saveApi = "https://expense-tool-api-industrious-possum-lh.cfapps.us10-001.hana.ondemand.com/save-invoices";

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    final cameras = await availableCameras();
    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );

    controller = CameraController(back, ResolutionPreset.medium);
    await controller!.initialize();

    setState(() {});
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  // Capture Image
  Future<void> captureImage() async {
    if (!controller!.value.isInitialized) return;

    final image = await controller!.takePicture();

    setState(() {
      images.add(image);
    });
  }

  // PROCESS API
  Future<void> processImages() async {
    setState(() {
      processing = true;
    });

    var request = http.MultipartRequest('POST', Uri.parse(processApi));

    for (var image in images) {
      request.files.add(await http.MultipartFile.fromPath('files', image.path));
    }

    var response = await request.send();
    var respStr = await response.stream.bytesToString();

    final data = jsonDecode(respStr);

    setState(() {
      apiResponse = data;

      if (data.isNotEmpty) {
        dateController.text = data[0]['date'];
        discrepencyController.text = data[0]['discrepencyAmt'].toString();
      }

      processing = false;
    });
  }

  // SAVE API
  Future<void> saveData() async {
    setState(() {
      saving = true;
    });

    apiResponse[0]['date'] = dateController.text;
    apiResponse[0]['discrepencyAmt'] =
        double.tryParse(discrepencyController.text) ?? 0;

    final body = {
      "user": "harshith.kandula@seleccionconsulting.com",
      "invoices": apiResponse,
    };

    final response = await http.post(
      Uri.parse(saveApi),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    setState(() {
      saving = false;
    });

    final message = jsonDecode(response.body);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("API Response"),
        content: Text(message.toString()),
      ),
    );
  }

  Future pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(dateController.text),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      dateController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Invoice Scanner"), centerTitle: true),
      body: controller == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// TITLE
                    const Text(
                      "Capture Invoice",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      "Take photos of invoice pages",
                      style: TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 16),

                    /// CAMERA
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CameraPreview(controller!),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// CAPTURE BUTTON
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: isLastPage ? null : captureImage,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Capture"),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// IMAGE PREVIEW
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (_, i) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(images[i].path),
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// CHECKBOX
                    Row(
                      children: [
                        Checkbox(
                          value: isLastPage,
                          onChanged: (v) {
                            setState(() {
                              isLastPage = v!;
                            });
                          },
                        ),
                        const Text("This is the last page"),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// PROCESS BUTTON
                    processing
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLastPage ? processImages : null,
                              child: const Text("Process"),
                            ),
                          ),

                    const SizedBox(height: 20),

                    /// API RESPONSE FIELDS
                    if (apiResponse.isNotEmpty) ...[
                      const Text(
                        "API Response",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: dateController,
                        readOnly: true,
                        onTap: pickDate,
                        decoration: const InputDecoration(
                          labelText: "Date",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: discrepencyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Discrepency Amount",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// SAVE BUTTON
                      saving
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: saveData,
                                child: const Text("Save"),
                              ),
                            ),
                    ],

                    const SizedBox(height: 30),

                    /// FOOTER
                    const Center(
                      child: Text(
                        "© Seleccion Consulting",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
