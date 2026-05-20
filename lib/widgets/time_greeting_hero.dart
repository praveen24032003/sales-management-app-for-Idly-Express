import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Time-of-day animated greeting hero.
/// Shows a sky gradient with a floating sun/moon and appropriate greeting.
class TimeGreetingHero extends StatefulWidget {
  final String businessName;
  const TimeGreetingHero({super.key, this.businessName = 'Idly Express'});

  @override
  State<TimeGreetingHero> createState() => _TimeGreetingHeroState();
}

class _TimeGreetingHeroState extends State<TimeGreetingHero>
    with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _glowCtrl;
  late final Animation<double> _floatAnim;
  late final Animation<double> _glowAnim;

  int get _hour => DateTime.now().hour;
  bool get _isNight => _hour >= 21 || _hour < 5;

  String get _greeting {
    if (_hour >= 5 && _hour < 12) return 'Good Morning';
    if (_hour >= 12 && _hour < 17) return 'Good Afternoon';
    if (_hour >= 17 && _hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  IconData get _bodyIcon {
    if (_isNight) return Icons.nightlight_round;
    if (_hour >= 17) return Icons.wb_twilight;
    return Icons.wb_sunny;
  }

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(vsync: this, duration: AppAnimations.float)
      ..repeat(reverse: true);
    _glowCtrl = AnimationController(vsync: this, duration: AppAnimations.glow)
      ..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
    _glowAnim = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = TimeGradients.getGradient(_hour, isDark);
    final sunMoonColor = TimeGradients.getSunMoonColor(_hour);

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          if (_isNight) _buildStars(),
          // Sun/Moon floating
          Positioned(
            top: 24,
            right: 32,
            child: AnimatedBuilder(
              animation: _floatAnim,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _floatAnim.value),
                child: AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (_, __) => Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sunMoonColor,
                      boxShadow: [
                        BoxShadow(
                          color: sunMoonColor.withOpacity(_glowAnim.value),
                          blurRadius: 24,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: Icon(
                      _bodyIcon,
                      color: Colors.white.withOpacity(0.9),
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Greeting text
          Positioned(
            bottom: 32,
            left: 24,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _greeting,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.businessName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStars() {
    final rng = math.Random(42);
    return Stack(
      children: List.generate(30, (i) {
        final x = rng.nextDouble();
        final y = rng.nextDouble() * 0.7;
        final size = 1.5 + rng.nextDouble() * 2;
        return Positioned(
          left: x * 400,
          top: y * 200,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5 + rng.nextDouble() * 0.5),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}
