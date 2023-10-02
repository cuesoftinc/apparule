import 'package:apparule/sms_verification.dart';
import 'package:flutter/material.dart';
import 'language_constants.dart';
import 'my_app_bar.dart';
import 'package:sms_autofill/sms_autofill.dart';

class VerifyAccount extends StatefulWidget {
  const VerifyAccount({super.key});

  @override
  State<VerifyAccount> createState() => _VerifyAccount();
}

class _VerifyAccount extends State<VerifyAccount> with TickerProviderStateMixin {
  int selectedOption = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyAppBar(),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.max, children: [
            Text(
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
              translation(context).verifyYourAccount,
            ),
            Container(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 16,
                ),
                translation(context).howToVerify,
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Column(children: [
            ListTile(
              horizontalTitleGap: 0,
              contentPadding: EdgeInsets.only(left: 4),
              title: Text(
                translation(context).receiveSms,
              ),
              leading: Radio<int>(
                value: 1,
                activeColor: Theme.of(context).colorScheme.primary,
                fillColor: MaterialStateProperty.all(Theme.of(context).colorScheme.primary),
                groupValue: selectedOption,
                splashRadius: 20,
                onChanged: (int? value) {
                  setState(() {
                    selectedOption = value!;
                  });
                },
              ),
            ),
            ListTile(
              horizontalTitleGap: 0,
              contentPadding: EdgeInsets.only(left: 4),
              title: Text(
                translation(context).receiveEmail,
              ),
              leading: Radio(
                value: 2,
                activeColor: Theme.of(context).colorScheme.primary,
                fillColor: MaterialStateProperty.all(Theme.of(context).colorScheme.primary),
                groupValue: selectedOption,
                splashRadius: 20,
                onChanged: (int? value) {
                  setState(() {
                    selectedOption = value!;
                  });
                },
              ),
            ),
          ]),
        ),
        Padding(
            padding: EdgeInsets.only(top: 20, right: 20),
            child: Container(
              height: 80,
              width: double.infinity,
              padding: const EdgeInsets.only(top: 25, left: 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0.0,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10), topRight: Radius.circular(10))),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SmsVerificationPage()),
                  );                },
                child: Text(translation(context).next),
              ),
            ))
      ]),
    );
  }
}
