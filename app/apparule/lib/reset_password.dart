import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:apparule/app_text_field.dart';
import 'package:flutter_svg/svg.dart';

import 'my_back_button.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  bool _obscured = false;
  late bool isMyButtonEnabled;
  final textFieldFocusNode = FocusNode();

  void _toggleObscured() {
    setState(() {
      _obscured = !_obscured;
      if (textFieldFocusNode.hasPrimaryFocus) return; // If focus is on text field, dont unfocus
      textFieldFocusNode.canRequestFocus = false; // Prevents focus if tap on eye
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 40.0, left: 5),
                child: MyBackButton(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        "Reset Your Password",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Theme.of(context).colorScheme.onBackground),
                      ),
                      Container(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          "Enter a new password below to reset your account password",
                          style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onBackground),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: AppTextField(
                          title: "New password",
                          hintText: "Enter your new password",
                          keyboardType: TextInputType.visiblePassword,
                          toggleObscured: _toggleObscured,
                          obscureText: _obscured,
                          nextAction: TextInputAction.next,
                          suffixIcon2: _obscured ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        ),
                      ),
                      AppTextField(
                        title: "Confirm password",
                        hintText: "Enter your new password",
                        keyboardType: TextInputType.visiblePassword,
                        toggleObscured: _toggleObscured,
                        obscureText: _obscured,
                        nextAction: TextInputAction.next,
                        suffixIcon2: _obscured ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          TextButton(
                              onPressed: () {},
                              child: Text(
                                "Both passwords must match",
                                style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                              )),
                        ],
                      ),
                      Container(
                        height: 80,
                        width: double.infinity,
                        padding: const EdgeInsets.only(top: 25, bottom: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            Widget okButton = Container(
                              height: 80,
                              width: double.infinity,
                              padding: const EdgeInsets.only(top: 25, bottom: 10),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0.0,
                                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10), topRight: Radius.circular(10))),
                                ),
                                child: const Text("Okay"),
                                onPressed: () {
                                  Navigator.of(context, rootNavigator: true).pop();
                                },
                              ),
                            );

                            BackdropFilter alert = BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8))),
                                iconPadding: EdgeInsets.only(top: 50),
                                contentPadding: EdgeInsets.fromLTRB(30, 10, 30, 0),
                                titlePadding: EdgeInsets.only(top: 20),
                                icon: SvgPicture.asset("assets/images/check.svg"),
                                title: Text("Successful"),
                                content: Text("Your password has been reset, please proceed to login",
                                  textAlign: TextAlign.center,
                                ),
                                actions: [
                                  okButton,
                                ],
                              ),
                            );

                            // show the dialog
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return alert;
                              },
                            );
                          },                    style: ElevatedButton.styleFrom(
                            elevation: 0.0,
                            backgroundColor: Theme.of(context).colorScheme.tertiary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10), topRight: Radius.circular(10))),
                          ),
                          child: Text("Reset Password"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
