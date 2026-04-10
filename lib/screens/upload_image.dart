import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class UploadScreen extends StatefulWidget {
  const UploadScreen({Key? key}) : super(key: key);

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _selectedImage;
  String _responseText = "";
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  // 🔹 Change this to your server IP
  final String apiUrl =
      "https://invoice-reimbursement-backend.cfapps.us10-001.hana.ondemand.com/api/v1/invoice-validation/flutter/image/process";
  // Android emulator: 10.0.2.2
  // iOS simulator: 127.0.0.1
  // Real device: use your PC's local IP

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _responseText = "";
      });
    }
  }

  Future<void> uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _responseText = "";
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // must match FastAPI parameter
          _selectedImage!.path,
        ),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      setState(() {
        _responseText = const JsonEncoder.withIndent(
          '  ',
        ).convert(json.decode(responseBody));
      });
    } catch (e) {
      setState(() {
        _responseText = "Error: $e";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image Analyzer"),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔹 Header
            const Text(
              "Upload an Image",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // 🔹 Upload Button
            ElevatedButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.upload),
              label: const Text("Choose Image"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Image Preview
            if (_selectedImage != null)
              Container(
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              ),

            const SizedBox(height: 20),

            // 🔹 Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : uploadImage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit"),
            ),

            const SizedBox(height: 20),

            // 🔹 Response Box
            const Text(
              "Response:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(12),
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _responseText.isEmpty
                      ? "Server response will appear here..."
                      : _responseText,
                  style: const TextStyle(fontSize: 14, color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
