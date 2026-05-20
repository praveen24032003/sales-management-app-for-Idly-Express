import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Wraps a child with a staggered fade+slide entrance animation.
/// Use [index] to stagger multiple form sections.
class AnimatedFormSection extends StatefulWidget {
  final Widget child;
  final int index;

  const AnimatedFormSection({super.key, required this.child, this.index = 0});

  @override
  State<AnimatedFormSection> createState() => _AnimatedFormSectionState();
}

class _AnimatedFormSectionState extends State<AnimatedFormSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppAnimations.slow);
    _fade = CurvedAnimation(parent: _ctrl, curve: AppAnimations.enter);
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: AppAnimations.spring));

    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
