import 'package:apparule/login_page.dart';
import 'package:apparule/sign_up_screen.dart';
import 'package:flutter/material.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/apparule.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Elevate your Fashion Design with Augmented Reality',
                style: TextStyle(color: Theme.of(context).colorScheme.onBackground, fontSize: 40, fontWeight: FontWeight.w600),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 50),
                child: Text(
                  "Unlock the future of fashion measurement with Apparule and get the perfect fit every time.",
                  style: TextStyle(color: Theme.of(context).colorScheme.onBackground, fontSize: 16),
                ),
              ),
              Container(
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
                  onPressed: () {
                    Navigator.of(context).push(_createSignUpRoute());
                  },
                  child: Text("I'm new here"),
                ),
              ),
              Container(
                height: 60,
                width: double.infinity,
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    elevation: 0.0,
                    shape: RoundedRectangleBorder(
                        side: BorderSide(color: Theme.of(context).colorScheme.onBackground),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10), topRight: Radius.circular(10))),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(_createLoginRoute());
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 8.0, top: 4.0),
                        child: Text(
                          "Login",
                          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Route _createSignUpRoute() {
  return PageRouteBuilder<SlideTransition>(
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (context, animation, secondaryAnimation) => const SignUpScreen(),
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

Route _createLoginRoute() {
  return PageRouteBuilder<SlideTransition>(
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
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
