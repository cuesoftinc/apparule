import 'package:apparule/measurement.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: GuideScreen(),
  ));
}

class GuideScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: OnboardingScreen(),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  PageController customPageController = PageController();

  int currentIndex = 0;

  final List<Widget> onboardingPagesList = [
    Page1(),
    Page2(),
    Page3(),
    Page4(),
    Page5(),
  ];

  @override
  void initState() {
    super.initState();
    customPageController = PageController(initialPage: currentIndex);
  }

  Material _skipButton() {
    return Material(
      color: Color.fromARGB(255, 21, 10, 50),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () {
          if (currentIndex < onboardingPagesList.length - 1) {
            setState(() {
              currentIndex++;
              customPageController.animateToPage(
                currentIndex,
                duration: Duration(milliseconds: 500),
                curve: Curves.ease,
              );
            });
          }
        },
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Icon(
            Icons.arrow_forward,
            color: Colors.blue,
            size: 20,
          ),
        ),
      ),
    );
  }

  Padding get _okButton {
    return Padding(
      padding: const EdgeInsets.only(left: 50),
      child: Container(
        width: 56,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0.0,
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
          ),
          onPressed: () {
    
          },
          child: const Text("Ok", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: customPageController,
                  itemCount: onboardingPagesList.length,
                  onPageChanged: (int pageIndex) {
                    setState(() {
                      currentIndex = pageIndex;
                    });
                  },
                  itemBuilder: (context, index) {
                    return onboardingPagesList[index];
                  },
                ),
              ),
              Container(
                color: Color.fromARGB(255, 21, 10, 50),
                padding: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomIndicators(
                      totalSlides: onboardingPagesList.length,
                      currentSlide: currentIndex,
                    ),
                    currentIndex == onboardingPagesList.length - 1
                        ? _okButton
                        : _skipButton(),
                  ],
                ),
              )
            ],
          ),
          Positioned(
            top: 60,
            left: 16,
            child: InkWell(
              onTap: () {
                if (currentIndex > 0) {
                  setState(() {
                    currentIndex--;
                    customPageController.animateToPage(
                      currentIndex,
                      duration: Duration(milliseconds: 500),
                      curve: Curves.ease,
                    );
                  });
                } else {
                 
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => Measurement()));
                }
              },
              child: Container(
                width: 35,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF002F6B),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/arrow.png',
                    width: 30,
                    height: 30,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomIndicators extends StatelessWidget {
  final int totalSlides;
  final int currentSlide;

  CustomIndicators({
    required this.totalSlides,
    required this.currentSlide,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSlides, (index) {
        return Container(
          width: 6,
          height: 6,
          margin: EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                currentSlide == index ? Color(0xFF54A0FE) : Color(0xFF002F6B),
          ),
        );
      }),
    );
  }
}

class Page1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.fromARGB(255, 21, 10, 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 120),
          Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              "How to Measure",
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 50),
          Center(
            child: Column(
              children: [
                Image.asset(
                  "assets/images/guide1.png",
                  width: 276,
                  height: 276,
                  fit: BoxFit.cover,
                ),
                SizedBox(height: 70),
                Center(
                  child: Text(
                    "Guide A-Z",
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 47),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "How to take your body measurement accurately",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Page2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.fromARGB(255, 21, 10, 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 120),
          Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              "How to Measure",
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 50),
          Center(
            child: Column(
              children: [
                Image.asset(
                  "assets/images/step2.jpg",
                  width: 545,
                  height: 365,
                  fit: BoxFit.cover,
                ),
                SizedBox(height: 50),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "1. Your clothes must fit skin tight around your body and if you have long hair please tie.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            "2. You must be bare feet but socks are allowed.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Page3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.fromARGB(255, 21, 10, 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 120),
          Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              "How to Measure",
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 50),
          Center(
            child: Column(
              children: [
                Image.asset(
                  "assets/images/guide3.png",
                  width: 545,
                  height: 365,
                ),
                SizedBox(height: 50),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "1. Place your phone vertically straight on a flat surface with your camera facing you and stand 5-6 feet away from your phone.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            "2. No other human should be in the screen",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Page4 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.fromARGB(255, 21, 10, 50),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 120),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  "How to Measure",
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 50),
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      "assets/images/guide4.png",
                      width: 545,
                      height: 365,
                    ),
                    SizedBox(height: 50),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "1. Stand straight in front of your phone with your head high.",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                "2. With both arms raised at 45 degrees approximately and your feet 1 foot apart",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Page5 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.fromARGB(255, 21, 10, 50),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 120),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  "How to Measure",
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 50),
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      "assets/images/guide5.png",
                      width: 545,
                      height: 365,
                    ),
                    SizedBox(height: 50),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "1. Turn right at 90 degrees",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                "2. Stand straight with your arms down",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
