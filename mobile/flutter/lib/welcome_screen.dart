import 'package:flutter/material.dart';
import 'measurement.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
         backgroundColor: Theme.of(context).colorScheme.secondary,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Image.asset(
                  'assets/images/Blur.jpg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              Positioned(
                top: 56,
                left: 16,
                child: Text(
                  "Welcome Baasit",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Center(
                child: Image.asset(
                  'assets/images/image2.jpg',
                  fit: BoxFit.cover,
                  width: 291,
                  height: 397,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: SizedBox(
          width: 40,
          height: 40,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => Measurement(),
                ),
              );
            },
            child: Icon(
              Icons.add,
              size: 20,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          color: Color(0xFF414D6D),
          height: 52,
          shape: const CircularNotchedRectangle(),
          notchMargin: 5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 48.0),
                child: IconButton(
                  icon: const Icon(
                    Icons.folder_open,
                    size: 20,
                    color: Color(0xFFE8E8E8),
                  ),
                  onPressed: () {},
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 48),
                child: IconButton(
                  icon: const Icon(Icons.settings),
                  color: Color(0xFFE8E8E8),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
