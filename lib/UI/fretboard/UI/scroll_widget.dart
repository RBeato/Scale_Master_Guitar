import 'package:flutter/material.dart';

class ScrollWidget extends StatelessWidget {
  const ScrollWidget({super.key, required this.child, this.controller});

  final Widget child;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: controller, // Add the controller here
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 50.0),
        child: child,
      ),
    );
  }
}
