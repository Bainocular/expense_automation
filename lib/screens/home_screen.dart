import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trial_exp_app/screens/capture_image_screen.dart';
import 'package:trial_exp_app/screens/generate_report_screen.dart';
import 'package:trial_exp_app/screens/splash_screen.dart';
import 'package:trial_exp_app/screens/track_miles_screen.dart';
import 'package:trial_exp_app/screens/trial_upload_save_screen.dart';
import 'package:trial_exp_app/services/shared_pref_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool showSettings = false;
  bool showNotifications = false;

  String? username = "";
  String? clientName = "Monster Energy";

  List<String> clients = [
    "Monster Energy",
    "Jacklinks",
    "Luxottica",
    "Public Storage",
    "SELECCION Internal",
  ];

  @override
  void initState() {
    super.initState();
    loadPrefs();
  }

  loadPrefs() async {
    // await PrefService.saveEmail(_emailController.text.trim());
    String? email = await PrefService.getEmail();
    String? client = await PrefService.getClient();
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // username = prefs.getString("username") ?? "User";
      // clientName = prefs.getString("client") ?? "Client A";
      username = email;
      clientName = client;
    });
  }

  saveClientName(String value) async {
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // await prefs.setString("client", value);
    await PrefService.saveClient(value);

    setState(() {
      clientName = value;
    });
  }

  logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const SplashScreen()));
    }
  }

  Widget homeButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(.05)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.blueGrey),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget settingsCard() {
    return Center(
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 330,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// CLOSE BUTTON
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      showSettings = false;
                    });
                  },
                ),
              ),

              /// ACCOUNT SECTION
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Account",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),

              const SizedBox(height: 10),

              ListTile(
                leading: const Icon(Icons.person),
                title: Text(username ?? "Guest"),
                subtitle: const Text("User"),
              ),

              DropdownButtonFormField(
                value: clientName,
                decoration: const InputDecoration(labelText: "Client Name"),
                items: clients.map((e) {
                  return DropdownMenuItem(value: e, child: Text(e));
                }).toList(),
                onChanged: (value) {
                  saveClientName(value!);
                },
              ),

              const SizedBox(height: 20),

              /// GENERAL SECTION
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "General",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),

              const SizedBox(height: 10),

              ListTile(
                leading: const Icon(Icons.straighten),
                title: const Text("Distance Metric"),
                subtitle: const Text("Miles"),
              ),

              const SizedBox(height: 20),

              /// LOGOUT BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: logout,
                  child: const Text("Logout"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget notificationCard() {
    return Center(
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 330,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      showNotifications = false;
                    });
                  },
                ),
              ),
              const Icon(
                Icons.notifications_none,
                size: 50,
                color: Colors.grey,
              ),
              const SizedBox(height: 10),
              const Text(
                "No notifications right now",
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      /// APPBAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            setState(() {
              showSettings = true;
              showNotifications = false;
            });
          },
        ),
        title: const Text("Dashboard", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              setState(() {
                showNotifications = true;
                showSettings = false;
              });
            },
          ),
        ],
      ),

      /// BODY
      body: Stack(
        children: [
          /// MAIN CONTENT
          Column(
            children: [
              const SizedBox(height: 20),

              /// TITLE
              const Text(
                "Welcome",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text("Client Name"),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: clientName,
                        items: clients.map((e) {
                          return DropdownMenuItem(value: e, child: Text(e));
                        }).toList(),
                        onChanged: (value) {
                          saveClientName(value!);
                        },
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// BUTTON GRID
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1.4,
                  children: [
                    homeButton(Icons.camera_alt, "Capture", () {
                      // Navigator.pushNamed(context, "/capture");
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DocumentCaptureScreen(),
                        ),
                      );
                    }),

                    homeButton(Icons.upload, "Upload", () {
                      // Navigator.pushNamed(context, "/upload");
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const UploadInvoiceScreen(),
                        ),
                      );
                    }),

                    homeButton(Icons.location_on, "Track", () {
                      // Navigator.pushNamed(context, "/track");
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const MilesScreen(),
                        ),
                      );
                    }),

                    homeButton(Icons.auto_graph, "Generate", () {
                      // Navigator.pushNamed(context, "/generate");
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const GenerateReportScreen(),
                        ),
                      );
                    }),

                    homeButton(Icons.history, "History", () {
                      // Navigator.pushNamed(context, "/history");
                    }),
                  ],
                ),
              ),

              const Spacer(),

              /// FOOTER
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "© 2026. SELECCION Consulting, Hyderabad.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),

          /// SETTINGS OVERLAY
          if (showSettings) settingsCard(),

          /// NOTIFICATION OVERLAY
          if (showNotifications) notificationCard(),
        ],
      ),
    );
  }
}
