import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trial_exp_app/screens/capture_image_screen.dart';
import 'package:trial_exp_app/screens/generate_report_screen.dart';
import 'package:trial_exp_app/screens/splash_screen.dart';
import 'package:trial_exp_app/screens/track_miles_screen.dart';
import 'package:trial_exp_app/screens/trial_upload_save_screen.dart';

class WebHomeScreen extends StatefulWidget {
  const WebHomeScreen({super.key});

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  String selectedValue = "Option 1";

  final List<String> dropdownItems = ["Option 1", "Option 2", "Option 3"];

  @override
  void initState() {
    super.initState();
    loadDropdownValue();
  }

  Future<void> loadDropdownValue() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedValue = prefs.getString("dropdown") ?? dropdownItems.first;
    });
  }

  Future<void> saveDropdownValue(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("dropdown", value);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }

  void navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget buildButton({
    required String title,
    required IconData icon,
    required Widget screen,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: ElevatedButton.icon(
        onPressed: () => navigateTo(screen),
        icon: Icon(icon),
        label: Text(title, textAlign: TextAlign.center),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSpacing = 12.0;

    final buttonWidth = (screenWidth - (buttonSpacing * 4)) / 3;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: logout,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Title
                Text(
                  "Welcome Back 👋",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),

                const SizedBox(height: 6),

                /// Subtitle
                Text(
                  "Manage your expenses efficiently",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 20),

                /// Dropdown
                DropdownButtonFormField<String>(
                  value: selectedValue,
                  items: dropdownItems
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedValue = value);
                      saveDropdownValue(value);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: "Select Option",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 24),

                /// Buttons (3 in first row)
                Wrap(
                  spacing: buttonSpacing,
                  runSpacing: buttonSpacing,
                  children: [
                    buildButton(
                      title: "Capture Receipt",
                      icon: Icons.camera_alt,
                      screen: const DocumentCaptureScreen(),
                      width: buttonWidth,
                    ),
                    buildButton(
                      title: "Upload Invoice",
                      icon: Icons.upload_file,
                      screen: const UploadInvoiceScreen(),
                      width: buttonWidth,
                    ),
                    buildButton(
                      title: "Track Miles",
                      icon: Icons.map,
                      screen: const MilesScreen(),
                      width: buttonWidth,
                    ),

                    /// Next row (2 buttons centered)
                    buildButton(
                      title: "Generate Report",
                      icon: Icons.bar_chart,
                      screen: const GenerateReportScreen(),
                      width: (screenWidth - (buttonSpacing * 3)) / 2,
                    ),
                    buildButton(
                      title: "View History",
                      icon: Icons.history,
                      screen: const MilesScreen(),
                      width: (screenWidth - (buttonSpacing * 3)) / 2,
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                /// Footer
                Center(
                  child: Text(
                    "© 2026 Your Company",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
