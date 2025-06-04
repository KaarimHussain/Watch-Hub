import 'dart:async';
import 'package:flutter/material.dart';

import 'package:watch_hub/components/logo.component.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Navigate to login screen after 3 seconds
    Timer(const Duration(milliseconds: 3000), () {
      Navigator.of(context).pushReplacementNamed('/auth');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              logoComponent(height: 120, width: 120),
              const SizedBox(height: 50),
              Text(
                "WATCH HUB",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              // Tagline
              Text(
                'PRECISION TIMEPIECES',
                style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
