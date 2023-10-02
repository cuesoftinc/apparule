import 'dart:async';
import 'package:apparule/verify_account.dart';
import 'package:flutter/material.dart';
import 'main.dart';
import 'persistence.dart';
import 'sign_up_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
        Duration(seconds: 3),
        () => Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Persistence.getUser() == null ? const SignUpScreen() : const VerifyAccount())));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Colors.white, Colors.grey]
            ),
    ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      Column(children: [
        Image.asset(
          'assets/images/logo.png',
          height: 200.0,
          width: 200.0,
        ),
      ]),
    ]),
    )
    );
  }
}
