import 'dart:async';
import 'package:apparule/language_constants.dart';
import 'package:apparule/login_page.dart';
import 'package:apparule/persistence.dart';
import 'package:apparule/verify_account.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'number_text_input_formatter.dart';
import 'form_provider.dart';
import 'package:apparule/app_text_field.dart';
import 'model/user.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key}) ;

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  late FormProvider _formProvider;
  final textFieldFocusNode = FocusNode();
  bool _obscured = false;
  late bool isMyButtonEnabled;
  final _mobileFormatter = NumberTextInputFormatter();

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
      body: buildForm(context),
    );
  }

  showLoaderDialog(BuildContext context) {
    AlertDialog alert = AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.background,
      content: Row(
        children: [
          CircularProgressIndicator(
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            color: Theme.of(context).colorScheme.onBackground,
          ),
          Container(
              margin: const EdgeInsets.only(left: 7),
              child: Text(
                translation(context).loading,
                style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
              )),
        ],
      ),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Route _createRoute() {
    return PageRouteBuilder<SlideTransition>(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) => const VerifyAccount(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween = Tween<Offset>(begin: const Offset(0.5, 1.0), end: Offset.zero);
        var curveTween = CurveTween(curve: Curves.fastOutSlowIn);

        return SlideTransition(
          position: animation.drive(curveTween).drive(tween),
          child: child,
        );
      },
    );
  }

  Widget buildForm(BuildContext context) {
    _formProvider = Provider.of<FormProvider>(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Theme.of(context).colorScheme.onBackground),
              translation(context).createAnAccount,
            ),
            Container(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onBackground),
                translation(context).startYourJourney,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: AppTextField(
                title: translation(context).fullName,
                hintText: translation(context).nameHint,
                errorText: _formProvider.name.error,
                onChanged: (text) => _formProvider.validateName(text, context),
                nextAction: TextInputAction.next,
              ),
            ),
            AppTextField(
              title: translation(context).emailAddress,
              hintText: translation(context).emailHint,
              errorText: _formProvider.email.error,
              onChanged: (text) => _formProvider.validateEmail(text, context),
              nextAction: TextInputAction.next,
            ),
            AppTextField(
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                _mobileFormatter,
              ],
              title: translation(context).phoneNumber,
              hintText: translation(context).phoneNumberHint,
              keyboardType: TextInputType.phone,
              errorText: _formProvider.phone.error,
              onChanged: (text) => _formProvider.validatePhone(text, context),
              nextAction: TextInputAction.next,
            ),
            AppTextField(
              title: translation(context).password,
              hintText: translation(context).passwordHint,
              keyboardType: TextInputType.visiblePassword,
              errorText: _formProvider.password.error,
              toggleObscured: _toggleObscured,
              obscureText: _obscured,
              onChanged: (text) => _formProvider.validatePassword(text, context),
              nextAction: TextInputAction.done,
              suffixIcon2: _obscured ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            ),
            Consumer<FormProvider>(builder: (context, model, child) {
              return Container(
                height: 80,
                width: double.infinity,
                padding: const EdgeInsets.only(top: 25, bottom: 10),
                child: ElevatedButton(
                  onPressed: () {
                    Persistence.saveUser(User(
                      email: _formProvider.email.value.toString(),
                      name: _formProvider.name.value.toString(),
                      phoneNumber: _formProvider.phone.value.toString(),
                    ));
                    if (true) {
                      showLoaderDialog(context);
                      Future.delayed(const Duration(seconds: 3), () {
                        Navigator.of(context).push(_createRoute());
                      });
                    } else {
                      Widget okButton = TextButton(
                        child: const Text("OK"),
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop();
                        },
                      );

                      // set up the AlertDialog
                      AlertDialog alert = AlertDialog(
                        title: Text(translation(context).signUp),
                        content: Text(translation(context).requiredField),
                        actions: [
                          okButton,
                        ],
                      );

                      // show the dialog
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return alert;
                        },
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0.0,
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10), topRight: Radius.circular(10))),
                  ),
                  child: Text(translation(context).signUp),
                ),
              );
            }),
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
                  translation(context).alreadyHaveAnAccount,
                  style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onBackground),
                ),
                TextButton(
                  child: Text(
                    translation(context).signIn,
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.tertiary),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
