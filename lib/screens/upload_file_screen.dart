import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class UploadFileScreen extends StatefulWidget {
  const UploadFileScreen({Key? key}) : super(key: key);

  @override
  State<UploadFileScreen> createState() => _UploadFileScreenState();
}

class _UploadFileScreenState extends State<UploadFileScreen> {
  File? _selectedImage;
  List<File> _selectedFiles = [];
  String _responseText = "";
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  // 🔹 Change this to your server IP
  // final String apiUrl = "https://invoice-reimbursement-backend.cfapps.us10-001.hana.ondemand.com/api/v1/invoice-validation/flutter/image/process";
  final String apiUrl = "https://expense-tool-api-industrious-possum-lh.cfapps.us10-001.hana.ondemand.com/read-invoices";
  // Android emulator: 10.0.2.2
  // iOS simulator: 127.0.0.1
  // Real device: use your PC's local IP

  void showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Upload Type"),
          content: const Text("Choose what you want to upload"),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                pickImage();
              },
              icon: const Icon(Icons.image),
              label: const Text("Upload Image"),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                pickDocument();
              },
              icon: const Icon(Icons.description),
              label: const Text("Upload Document"),
            ),
          ],
        );
      },
    );
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _responseText = "";
      });
    }
  }

  Future<void> pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedImage = File(result.files.single.path!);
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
      print("Calling api...");
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      request.files.add(
        await http.MultipartFile.fromPath(
          'files', // must match FastAPI parameter
          _selectedImage!.path,
        ),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      setState(() {
        _responseText = const JsonEncoder.withIndent(
          '  ',
        ).convert(json.decode(responseBody));
        print(responseBody);
        // _responseText = json.decode(responseBody);
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
              onPressed: showUploadDialog,
              icon: const Icon(Icons.upload),
              label: const Text("Choose File"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),

            const SizedBox(height: 20),

            if (_selectedImage != null)
              Container(
                height: 250,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    _selectedImage!.path.endsWith(".png") ||
                        _selectedImage!.path.endsWith(".jpg") ||
                        _selectedImage!.path.endsWith(".jpeg")
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.description, size: 80, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("Document Selected"),
                        ],
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
                      ? "Response will appear here..."
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
