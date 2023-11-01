import 'package:apparule/app_text_field.dart';
import 'package:apparule/custom_tab_indicator.dart';
import 'package:apparule/sign_up_screen.dart';
import 'package:apparule/welcome_screen.dart';
import 'package:flutter/material.dart';

import 'forgot_password.dart';
import 'language_constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Column(children: [
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          "Welcome Back",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Theme.of(context).colorScheme.onBackground),
                        ),
                        Container(
                          padding: const EdgeInsets.only(top: 10, bottom: 24),
                          child: Text(
                            'Login to continue designing your perfect fit',
                            style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onBackground),
                          ),
                        ),
                        Expanded(
                            child: DefaultTabController(
                                length: 2,
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Container(
                                      decoration: ShapeDecoration(
                                          color: Theme.of(context).colorScheme.secondary, shape: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                                      child: TabBar(padding: EdgeInsets.only(left: 8, right: 8), indicator: CustomTabIndicator(), tabs: [
                                        Tab(text: "Email"),
                                        Tab(text: "Phone"),
                                      ])),
                                  Expanded(
                                    child: TabBarView(children: [
                                      buildLoginWithEmail(context),
                                      buildLoginWithPhone(context),
                                    ]),
                                  )
                                ])))
                      ])))
        ]));
  }

  Widget buildLoginWithEmail(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        child: Padding(
          padding: const EdgeInsets.only(top: 28.0),
          child: Column(
            children: [
              AppTextField(
                title: translation(context).emailAddress,
                hintText: translation(context).emailHint,
                nextAction: TextInputAction.next,
              ),
              AppTextField(
                title: translation(context).password,
                hintText: translation(context).passwordHint,
                nextAction: TextInputAction.done,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => ForgotPassword()));
                      },
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
                      )),
                ],
              ),
              Container(
                height: 80,
                width: double.infinity,
                padding: const EdgeInsets.only(top: 25, bottom: 10),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=> WelcomeScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0.0,
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10), topRight: Radius.circular(10))),
                  ),
                  child: Text(translation(context).signIn),
                ),
              ),
              Container(
                height: 60,
                width: double.infinity,
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    elevation: 0.0,
                    shape: RoundedRectangleBorder(
                        side: BorderSide(color: Theme.of(context).colorScheme.onBackground),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10), topRight: Radius.circular(10))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.network('http://pngimg.com/uploads/google/google_PNG19635.png', fit: BoxFit.cover),
                      Padding(
                        padding: EdgeInsets.only(left: 8.0, top: 4.0),
                        child: Text(
                          translation(context).continueWithGoogle,
                          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Don't have an account",
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onBackground),
                  ),
                  TextButton(
                    child: Text(
                      translation(context).signUp,
                      style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.tertiary),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SignUpScreen()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLoginWithPhone(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        child: Padding(
          padding: const EdgeInsets.only(top: 28.0),
          child: Column(
            children: [
              AppTextField(
                title: translation(context).phoneNumber,
                hintText: translation(context).phoneNumberHint,
                nextAction: TextInputAction.next,
              ),
              AppTextField(
                title: translation(context).password,
                hintText: translation(context).passwordHint,
                nextAction: TextInputAction.done,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () {},
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
                      )),
                ],
              ),
              Container(
                height: 80,
                width: double.infinity,
                padding: const EdgeInsets.only(top: 25, bottom: 10),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    elevation: 0.0,
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10), topRight: Radius.circular(10))),
                  ),
                  child: Text(translation(context).signIn),
                ),
              ),
              Container(
                height: 60,
                width: double.infinity,
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    elevation: 0.0,
                    shape: RoundedRectangleBorder(
                        side: BorderSide(color: Theme.of(context).colorScheme.onBackground),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10), topRight: Radius.circular(10))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.network('http://pngimg.com/uploads/google/google_PNG19635.png', fit: BoxFit.cover),
                      Padding(
                        padding: EdgeInsets.only(left: 8.0, top: 4.0),
                        child: Text(
                          translation(context).continueWithGoogle,
                          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Don't have an account",
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onBackground),
                  ),
                  TextButton(
                    child: Text(
                      translation(context).signUp,
                      style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.tertiary),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SignUpScreen()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
