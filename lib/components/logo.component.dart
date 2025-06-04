import 'dart:math';
import 'package:flutter/material.dart';

Widget logoComponent({double height = 60, double width = 60}) {
  // Ensure the logo is a perfect circle by using the smaller dimension
  final size = min(height, width);

  // Calculate proportional sizes for elements
  final outerCircleSize = size;
  final innerCircleSize = size * 0.85;
  final centerDotSize = size * 0.08;
  final hourHandLength = size * 0.3;
  final hourHandWidth = size * 0.04;
  final minuteHandLength = size * 0.4;
  final minuteHandWidth = size * 0.025;

  // Modern dark color palette
  final backgroundColor = const Color(0xFF1A1A1A); // Dark background
  final primaryColor = const Color(0xFFE0E0E0); // Light gray for contrast
  final accentColor = Colors.transparent;

  return SizedBox(
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        // Outer circle with subtle glow
        Container(
          width: outerCircleSize,
          height: outerCircleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.15),
                blurRadius: size * 0.1,
                spreadRadius: size * 0.01,
              ),
            ],
          ),
        ),

        // Inner circle (watch face)
        Container(
          width: innerCircleSize,
          height: innerCircleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            border: Border.all(
              color: primaryColor.withOpacity(0.7),
              width: size * 0.02,
            ),
          ),
        ),

        // Minimal hour markers (just at 12, 3, 6, 9)
        ...List.generate(4, (index) {
          final angle = (index * 90) * (pi / 180); // Convert to radians
          final markerDistance = innerCircleSize * 0.38;
          final markerSize = size * 0.06;

          return Transform(
            alignment: Alignment.center,
            transform:
                Matrix4.identity()..translate(
                  markerDistance * sin(angle),
                  -markerDistance * cos(angle),
                ),
            child: Container(
              width: markerSize,
              height: markerSize,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          );
        }),

        // Hour hand (shorter)
        Transform.rotate(
          angle: 0.5, // Positioned at around 2 o'clock
          child: Container(
            width: hourHandWidth,
            height: hourHandLength,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(hourHandWidth * 0.5),
            ),
            margin: EdgeInsets.only(bottom: hourHandLength),
          ),
        ),

        // Minute hand (longer)
        Transform.rotate(
          angle: 2.0, // Positioned at around 7 o'clock
          child: Container(
            width: minuteHandWidth,
            height: minuteHandLength,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(minuteHandWidth * 0.5),
            ),
            margin: EdgeInsets.only(bottom: minuteHandLength),
          ),
        ),

        // Accent element (glowing blue circle)
        Container(
          width: size * 0.15,
          height: size * 0.15,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor,
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.4),
                blurRadius: size * 0.05,
                spreadRadius: size * 0.01,
              ),
            ],
          ),
          margin: EdgeInsets.only(bottom: size * 0.3),
        ),

        // Center cap
        Container(
          width: centerDotSize,
          height: centerDotSize,
          decoration: BoxDecoration(
            color: accentColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.3),
                blurRadius: size * 0.03,
                spreadRadius: size * 0.01,
              ),
            ],
          ),
        ),

        // Minimal brand indicator
        Positioned(
          bottom: size * 0.25,
          child: Text(
            "W",
            style: TextStyle(
              color: primaryColor,
              fontSize: size * 0.12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}
