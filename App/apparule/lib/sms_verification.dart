import 'package:apparule/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';

class SmsVerificationPage extends StatefulWidget {
  const SmsVerificationPage({Key? key}) : super(key: key);

  @override
  State<SmsVerificationPage> createState() => _SmsVerificationPageState();
}

class _SmsVerificationPageState extends State<SmsVerificationPage> with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  int levelClock = 2 * 60;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(seconds: levelClock));

    _animationController!.forward();

    _listenSmsCode();
  }

  @override
  void dispose() {
    SmsAutoFill().unregisterListener();
    _animationController!.dispose();
    super.dispose();
  }

  _listenSmsCode() async {
    await SmsAutoFill().listenForCode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SMS OTP AutoFill"),
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
                    "Check your SMS inbox for the code sent to (123) 456-7890. Enter the code below to complete the verification",
                    style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onBackground),
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
                // ?  use this code to get sms signature for your app
                final String signature = await SmsAutoFill().getAppSignature;
                print("Signature: $signature");

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
                //Confirm and Navigate to Home Page
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

class Countdown extends AnimatedWidget {
  Countdown({Key? key, required this.animation}) : super(key: key, listenable: animation);
  Animation<int> animation;

  @override
  build(BuildContext context) {
    Duration clockTimer = Duration(seconds: animation.value);
    String timerText = '${clockTimer.inMinutes.remainder(60).toString()}:${clockTimer.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    return Text(
      timerText,
      style: TextStyle(
        fontSize: 18,
        color: Theme.of(context).colorScheme.onBackground,
      ),
    );
  }
}
