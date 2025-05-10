import 'dart:math';

import 'package:flutter/material.dart';

Widget logoComponent({int height = 60, int width = 60}) {
  return Container(
    width: width.toDouble(),
    height: height.toDouble(),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFF333333), width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ],
    ),
    child: Center(
      child: Container(
        width: width * 0.6,
        height: height * 0.6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFF333333), Color(0xFF222222)],
            stops: [0.5, 1.0],
          ),
          border: Border.all(color: const Color(0xFF444444), width: 1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Clock face with hour markers
            ...List.generate(12, (index) {
              final angle =
                  (index * 30) * (3.14159 / 180); // Convert to radians
              final isMainMarker = index % 3 == 0; // 12, 3, 6, 9 positions
              final markerHeight = isMainMarker ? 4.0 : 2.0;
              final markerWidth = isMainMarker ? 1.5 : 1.0;
              final distance = 22.0; // Distance from center

              return Transform(
                alignment: Alignment.center,
                transform:
                    Matrix4.identity()..translate(
                      distance * sin(angle),
                      -distance * cos(angle),
                    ),
                child: Container(
                  width: markerWidth,
                  height: markerHeight,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isMainMarker ? 1.0 : 0.7),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              );
            }),

            // Hour hand (shorter, thicker)
            Transform.rotate(
              angle: 0.5, // Positioned at around 2 o'clock
              child: Container(
                width: 2.5,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1.5),
                ),
                margin: const EdgeInsets.only(bottom: 10),
              ),
            ),

            // Minute hand (longer, thinner)
            Transform.rotate(
              angle: 2.0, // Positioned at around 7 o'clock
              child: Container(
                width: 1.5,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1),
                ),
                margin: const EdgeInsets.only(bottom: 10),
              ),
            ),

            // Second hand (thin with red accent)
            Transform.rotate(
              angle: 4.2, // Positioned at around 4 o'clock
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    width: 1.0,
                    height: 20,
                    color: Colors.red.shade400,
                    margin: const EdgeInsets.only(bottom: 10),
                  ),
                  Container(
                    width: 3.0,
                    height: 3.0,
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                    margin: const EdgeInsets.only(top: 17),
                  ),
                ],
              ),
            ),

            // Center dot where hands meet
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 1,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
