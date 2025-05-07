import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:watch_hub/screens/base/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _outerCircleAnimation;
  late Animation<double> _middleCircleAnimation;
  late Animation<double> _innerCircleAnimation;
  late Animation<double> _handAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _logoRotationAnimation = Tween<double>(
      begin: -math.pi / 2,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _outerCircleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
      ),
    );

    _middleCircleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.6, curve: Curves.easeOut),
      ),
    );

    _innerCircleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.8, curve: Curves.easeOut),
      ),
    );

    _handAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );

    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.8, curve: Curves.easeOut),
      ),
    );

    _textSlideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.8, curve: Curves.easeOut),
      ),
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _controller.forward();

    // Navigate to home screen after animation completes
    Future.delayed(const Duration(milliseconds: 2800), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.0;
            const end = 1.0;
            const curve = Curves.easeInOut;
            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            var fadeAnimation = animation.drive(tween);
            return FadeTransition(opacity: fadeAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with concentric circles
                ScaleTransition(
                  scale: _logoScaleAnimation,
                  child: SizedBox(
                    width: 128,
                    height: 128,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer circle with progress indicator
                        CustomPaint(
                          size: const Size(128, 128),
                          painter: ProgressArcPainter(
                            progress: _progressAnimation.value,
                            color: Colors.white,
                          ),
                        ),

                        // Outer circle
                        Transform.rotate(
                          angle: _logoRotationAnimation.value,
                          child: Opacity(
                            opacity: _outerCircleAnimation.value,
                            child: Container(
                              width: 128,
                              height: 128,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF333333),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Middle circle
                        Opacity(
                          opacity: _middleCircleAnimation.value,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF444444),
                                width: 1,
                              ),
                            ),
                          ),
                        ),

                        // Inner circle
                        Opacity(
                          opacity: _innerCircleAnimation.value,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF555555),
                                width: 1,
                              ),
                              gradient: const RadialGradient(
                                colors: [Color(0xFF333333), Color(0xFF222222)],
                                stops: [0.5, 1.0],
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Hour hand
                                Opacity(
                                  opacity: _handAnimation.value,
                                  child: Container(
                                    width: 2,
                                    height: 24,
                                    color: Colors.white,
                                  ),
                                ),
                                // Minute hand
                                Opacity(
                                  opacity: _handAnimation.value,
                                  child: Transform.rotate(
                                    angle: math.pi / 2,
                                    child: Container(
                                      width: 2,
                                      height: 32,
                                      color: Colors.white,
                                      margin: const EdgeInsets.only(right: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Brand name and tagline
                Opacity(
                  opacity: _textOpacityAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _textSlideAnimation.value),
                    child: Column(
                      children: [
                        const Text(
                          'WATCH HUB',
                          style: TextStyle(
                            fontFamily: 'Cal_Sans',
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'PRECISION TIMEPIECES',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 12,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Custom painter for the circular progress indicator
class ProgressArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  ProgressArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2,
    );

    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

    // Draw the progress arc
    canvas.drawArc(
      rect,
      -math.pi / 2, // Start from the top
      2 * math.pi * progress, // Draw based on progress
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant ProgressArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
