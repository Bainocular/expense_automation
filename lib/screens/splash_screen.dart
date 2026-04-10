import 'package:flutter/material.dart';
import 'package:trial_exp_app/screens/home_screen.dart';
import 'package:trial_exp_app/screens/intro_slider_screen.dart';
import 'package:trial_exp_app/screens/trial_homepage.dart';
import 'package:trial_exp_app/services/shared_pref_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {

    await Future.delayed(const Duration(seconds: 2));

    // final prefs = await SharedPreferences.getInstance();
    // String? email = prefs.getString('user_email');
    String? email = await PrefService.getEmail();

    if (email != null && email.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const IntroductionSliderScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            /// Logo
            Image.asset(
              "assets/images/seleccion-logo-png.png",
              height: 120,
            ),

            const SizedBox(height: 40),

            /// Loading animation
            const CircularProgressIndicator(),

            const SizedBox(height: 20),

            const Text(
              "Loading...",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            )
          ],
        ),
      ),
    );
  }
}