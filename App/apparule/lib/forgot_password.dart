import 'package:apparule/app_text_field.dart';
import 'package:apparule/my_back_button.dart';
import 'package:flutter/material.dart';

import 'language_constants.dart';
import 'verify_email.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 40.0, left: 5),
            child: MyBackButton(),
          ),
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: SingleChildScrollView(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                    Text(
                      'Forgot Password',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Theme.of(context).colorScheme.onBackground),
                    ),
                    Container(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'No worries! enter the email address associated with your account, and we\'ll send you a code.',
                        style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onBackground),
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child:
                            AppTextField(hintText: translation(context).emailHint, title: translation(context).emailAddress, nextAction: TextInputAction.none)),
                    Container(
                      height: 80,
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 25, bottom: 10),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => VerifyEmailForPasswordReset()));
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0.0,
                          backgroundColor: Theme.of(context).colorScheme.tertiary,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10), topRight: Radius.circular(10))),
                        ),
                        child: Text("Submit"),
                      ),
                    )
                  ]))),
        ],
      ),
    );
  }
}
