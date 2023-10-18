import 'package:apparule/sign_up_form.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'form_provider.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(create: (_) => FormProvider(), child: const SignUpForm());
  }
}
