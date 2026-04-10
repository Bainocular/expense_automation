import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';

import 'package:trial_exp_app/screens/otp_login_screen.dart';
import 'package:trial_exp_app/services/user_registration.dart';

class IntroductionSliderScreen extends StatefulWidget {
  const IntroductionSliderScreen({super.key});

  @override
  State<IntroductionSliderScreen> createState() {
    return _IntroductionSliderScreenState();
  }
}

class _IntroductionSliderScreenState extends State<IntroductionSliderScreen> {
  Widget buildImage(String imagePath) {
    return Center(child: Image.asset(imagePath, width: 450, height: 200));
  }

  PageDecoration getPageDecoration() {
    return const PageDecoration(
      imagePadding: EdgeInsets.only(top: 120),
      pageColor: Colors.white,
      bodyPadding: EdgeInsets.only(top: 8, left: 20, right: 20),
      titlePadding: EdgeInsets.only(top: 50),
      bodyTextStyle: TextStyle(color: Colors.orange, fontSize: 15),
    );
  }

  DotsDecorator getDotsDecorator() {
    return const DotsDecorator(
      spacing: EdgeInsets.symmetric(horizontal: 2),
      activeColor: Colors.indigo,
      color: Colors.grey,
      activeSize: Size(12, 5),
      activeShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(25.0)),
      ),
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(),
      body: IntroductionScreen(
        pages: [
          PageViewModel(
            title: 'EXPENSE AUTOMATION TOOL',
            body: 'Designed and Developed by SELECCION Hyderabad',
            image: buildImage("assets/images/seleccion-logo-png.png"),
            decoration: getPageDecoration(),
          ),
          PageViewModel(
            title: 'Manage Invoices Efficiently',
            body: 'Manage your invoices just from your mobile',
            image: buildImage("assets/images/intro1.jpg"),
            decoration: getPageDecoration(),
          ),
          PageViewModel(
            title: 'Hassle-free reimbursement',
            body: 'Transparency all over the process',
            image: buildImage("assets/images/intro4.jpg"),
            decoration: getPageDecoration(),
          ),
          PageViewModel(
            title: 'Capture or Upload',
            body:
                'Either capture, or upload, or enter the invoice details',
            image: buildImage("assets/images/intro.jpg"),
            decoration: getPageDecoration(),
          ),
          PageViewModel(
            title: 'Consolidation made easy',
            body: 'Categorizing and summing up faster than ever',
            image: buildImage("assets/images/intro3.png"),
            decoration: getPageDecoration(),
          ),
          PageViewModel(
            title: "AI based Automation",
            body:
                'AI-powered automation for quick validation and easy generating report',
            image: buildImage("assets/images/intro6.jpg"),
            decoration: getPageDecoration(),
          ),
        ],
        onDone: () {
          // print(getDevicePlatform());
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OTPLoginScreen()),
          );
        },
        scrollPhysics: const ClampingScrollPhysics(),
        showDoneButton: true,
        showNextButton: true,
        showSkipButton: true,
        skip: const Text("Skip", style: TextStyle(fontWeight: FontWeight.w600)),
        next: const Icon(Icons.navigate_next),
        done: const Text(
          "Lets go!",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        dotsDecorator: getDotsDecorator(),
      ),
    );
  }
}
