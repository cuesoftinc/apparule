import 'package:flutter/material.dart';

class MyBackButton extends StatelessWidget {
  const MyBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(
        Icons.arrow_circle_left,
        color: Colors.white,
        size: 40,
      ),
      label: const Text(''),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
