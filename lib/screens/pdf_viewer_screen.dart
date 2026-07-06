import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatelessWidget {
  final String filePath;

  const PdfViewerScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Invoice Preview',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      body: SfPdfViewer.file(File(filePath)),
    );
  }
}
