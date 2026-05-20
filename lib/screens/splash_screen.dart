import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_shell.dart';

/// Professional animated splash screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final AnimationController _fadeCtrl;
  late final AnimationController _progressCtrl;
  late final AnimationController _pulseCtrl;

  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _progressAnim;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0C0C14),
    ));

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _progressAnim = CurvedAnimation(
      parent: _progressCtrl,
      curve: Curves.easeInOut,
    );
    _pulseAnim = Tween<double>(begin: 0.90, end: 1.10).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 250));
    _scaleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 420));
    _fadeCtrl.forward();
    _progressCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, routeAnim, secondaryAnim) => const HomeShell(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _fadeCtrl.dispose();
    _progressCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C14),
      body: Stack(
        children: [
          // Ambient glow background
          _AmbientBackground(pulseAnim: _pulseAnim),

          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Logo with rings
                ScaleTransition(
                  scale: _scaleAnim,
                  child: _AnimatedLogo(pulseAnim: _pulseAnim),
                ),

                const SizedBox(height: 40),

                // App name + tagline
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFFFF8A50), Color(0xFFFFCC02)],
                        ).createShader(b),
                        child: const Text(
                          'IDLY EXPRESS',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'SMART BUSINESS TRACKER',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF5A5A72),
                          letterSpacing: 3.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                // Loading bar
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: AnimatedBuilder(
                      animation: _progressAnim,
                      builder: (_, _) => Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                height: 2,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E2E),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: _progressAnim.value,
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF7043),
                                        Color(0xFFFFCC02),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF7043)
                                            .withValues(alpha: 0.7),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Loading... ${(_progressAnim.value * 100).toInt()}%',
                            style: const TextStyle(
                              color: Color(0xFF3A3A4E),
                              fontSize: 11,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 52),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedLogo extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _AnimatedLogo({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, _) {
        return SizedBox(
          width: 148,
          height: 148,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: 148 * (0.6 + pulseAnim.value * 0.4),
                height: 148 * (0.6 + pulseAnim.value * 0.4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF7043).withValues(alpha: 0.06 * pulseAnim.value),
                ),
              ),
              // Middle ring
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF7043)
                        .withValues(alpha: 0.20 * pulseAnim.value),
                    width: 1.0,
                  ),
                ),
              ),
              // Inner ring
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF9800)
                        .withValues(alpha: 0.15 * pulseAnim.value),
                    width: 1.0,
                  ),
                ),
              ),
              // Logo container with gradient + glow
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF8A50), Color(0xFFDD2C00)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7043)
                          .withValues(alpha: 0.55 * pulseAnim.value),
                      blurRadius: 28,
                      spreadRadius: 3,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFF3D00).withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, errorObj, stackTrace) => const Icon(
                      Icons.restaurant_menu,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _AmbientBackground({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, _) => CustomPaint(
        painter: _GlowPainter(pulseAnim.value),
        size: Size.infinite,
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final double pulse;
  _GlowPainter(this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);

    paint.color = const Color(0xFFFF7043).withValues(alpha: 0.07 * pulse);
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.12),
      size.width * 0.55,
      paint,
    );

    paint
      ..color = const Color(0xFF3D5AFE).withValues(alpha: 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.88),
      size.width * 0.50,
      paint,
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.pulse != pulse;
}
