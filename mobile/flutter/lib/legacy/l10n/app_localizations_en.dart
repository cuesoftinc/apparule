// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get createAnAccount => 'Create an Account';

  @override
  String get startYourJourney =>
      'Start your journey toward perfect fits and customized style';

  @override
  String get fullName => 'Full Name';

  @override
  String get nameHint => 'Enter your name';

  @override
  String get nameValidation => 'Please enter a valid name';

  @override
  String get emailAddress => 'Email';

  @override
  String get emailHint => 'Enter your email address';

  @override
  String get emailValidation => 'Please enter a valid email';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get phoneNumberHint => 'Enter your phone number';

  @override
  String get phoneValidation => 'Phone Number must be up to 12 digits';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get passwordValidation =>
      'Password must contain an uppercase, lowercase, numeric digit and special character';

  @override
  String get requiredField => 'You have to fill all the fields properly.';

  @override
  String get signUp => 'Sign Up';

  @override
  String get loading => 'Loading...';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get alreadyHaveAnAccount => 'Already have an account?';

  @override
  String get signIn => 'Sign In';

  @override
  String get verifyYourAccount => 'Verify Your Account';

  @override
  String get howToVerify =>
      'To verify your account, please choose how you\'d like to receive your verification code';

  @override
  String get receiveSms => 'Receive the code via SMS ';

  @override
  String get receiveEmail => 'Receive the code in your email inbox';

  @override
  String get next => 'Next';
}
