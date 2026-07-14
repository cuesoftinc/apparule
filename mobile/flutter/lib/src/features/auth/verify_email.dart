import 'package:apparule/src/app/home_screen.dart';
import 'package:apparule/src/features/auth/reset_password.dart';
import 'package:apparule/src/shared/countdown.dart';
import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';

class VerifyEmailForPasswordReset extends StatefulWidget {
  const VerifyEmailForPasswordReset({Key? key}) : super(key: key);

  @override
  State<VerifyEmailForPasswordReset> createState() => _VerifyEmailForPasswordResetState();
}

class _VerifyEmailForPasswordResetState extends State<VerifyEmailForPasswordReset> with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  int levelClock = 2 * 60;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(seconds: levelClock));

    _animationController!.forward();
  }

  void sendOTP() async {
    // TODO: request an OTP from the backend. Client-side OTP handling was
    // removed for security — OTP send/verify must happen server-side.
  }

  void verifyOTP() {
    // TODO: verify the OTP against the backend (server-side).
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Email OTP AutoFill"),
        titleTextStyle: TextStyle(color: Theme.of(context).colorScheme.onBackground, fontSize: 20),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    "Verify Your Account",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Theme.of(context).colorScheme.onBackground),
                  ),
                  Text(
                    "Check your Email inbox for the code sent to ${Persistence.getUser()?.email ?? 'your email'}. Enter the code below to complete the verification",
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onBackground),
                  ),
                ],
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PinFieldAutoFill(
                  codeLength: 6,
                  autoFocus: true,
                  decoration: UnderlineDecoration(
                    lineHeight: 2,
                    lineStrokeCap: StrokeCap.square,
                    bgColorBuilder: PinListenColorBuilder(Colors.green.shade200, Colors.grey.shade200),
                    colorBuilder: const FixedColorBuilder(Colors.transparent),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Resend code after: ",
                  style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                ),
                Countdown(
                  animation: StepTween(
                    begin: levelClock, // THIS IS A USER ENTERED NUMBER
                    end: 0,
                  ).animate(_animationController!),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                _animationController!.reset();
                _animationController!.forward();
              },
              child: const Text("Resend"),
            ),
          ),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ResetPassword(),)
                );
              },
              child: const Text("Confirm"),
            ),
          ),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
              },
              child: const Text("Log Out"),
            ),
          ),
        ],
      ),
    );
  }
}

