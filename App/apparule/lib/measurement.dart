import 'package:apparule/guide_screen.dart';
import 'package:apparule/welcome_screen.dart';
import 'package:flutter/material.dart';

class Measurement extends StatefulWidget {
  const Measurement({super.key});

  @override
  State<Measurement> createState() => _MeasurementState();
}

class _MeasurementState extends State<Measurement> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       
      home: Scaffold(
                 backgroundColor: Theme.of(context).colorScheme.secondary,
        body: Stack(
          children: [
            Center(
              child: Image.asset(
                'assets/images/measurement.jpg',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              top: 340,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (context) => GuideScreen()));
                },
                child: Card(
                  color: Color.fromRGBO(20, 5, 98, 0.837),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: BorderSide(
                      color: Color(0xFF5A5A5A),
                      width: 1.0,
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 142,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 23,
                          child: Image.asset(
                            'assets/images/howToMeasure.jpg',
                            width: 69,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          bottom: 21,
                          child: Text(
                            "How to Measure",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 506,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {},
                child: Card(
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: BorderSide(
                      color: Color(0xFF5A5A5A),
                      width: 1.0,
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 142,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 23,
                          child: Transform.scale(
                            scale: 0.5,
                            child: Image.asset(
                              'assets/images/takeMeasure.jpg',
                              width: 170,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 21,
                          child: Text(
                            "Take Measurement",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: SizedBox(
          width: 40,
          height: 40,
          child: FloatingActionButton(
            onPressed: () {
                           Navigator.of(context).push(MaterialPageRoute(builder: (context) => WelcomeScreen()));
            },
            child: Icon(
              Icons.close,
              size: 20,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
