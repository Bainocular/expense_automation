// import 'dart:convert';
// import 'package:uuid/uuid.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

String getDevicePlatform() {
  String deviceOS = "Unknown";
  if (Platform.isAndroid) {
    deviceOS = "Android";
  } else if (Platform.isIOS) {
    deviceOS = "iOS";
  } else if (Platform.isMacOS) {
    deviceOS = "MacOS";
  } else if (Platform.isWindows) {
    deviceOS = "Windows";
  } else {
    deviceOS = "Unknown";
  }
  return deviceOS;
}