import 'package:flutter/material.dart';

class MetronomePainter extends CustomPainter {
  final bool isOn;

  MetronomePainter({required this.isOn});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = isOn ? Colors.greenAccent : Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw the triangle
    final trianglePath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.1) // top of the triangle
      ..lineTo(
          size.width * 0.1, size.height * 0.9) // bottom left of the triangle
      ..lineTo(
          size.width * 0.9, size.height * 0.9) // bottom right of the triangle
      ..close(); // closes the path to create a triangle
    canvas.drawPath(trianglePath, paint);

    // Calculate the center of the bottom line of the triangle
    final double bottomCenterX = size.width * 0.5;
    final double bottomCenterY = size.height * 0.9;

    // Draw the vertical line from the bottom center of the triangle
    final double lineLength = size.height * 0.4; // Adjust the length as needed
    final verticalLinePath = Path()
      ..moveTo(bottomCenterX, bottomCenterY)
      ..lineTo(bottomCenterX, bottomCenterY - lineLength);
    paint.strokeWidth = 2.0; // Set the stroke width for the line
    canvas.drawPath(verticalLinePath, paint);

    // Draw the small ball at the top of the vertical line
    final double ballRadius =
        size.width * 0.05; // Adjust the ball radius as needed
    final ballCenterY = bottomCenterY - lineLength;
    canvas.drawCircle(
      Offset(bottomCenterX, ballCenterY),
      ballRadius,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
