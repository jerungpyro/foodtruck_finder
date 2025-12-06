import 'dart:ui';
import 'package:flutter/material.dart';

/// A glassmorphism container widget with blur effects and transparency
/// Following Apple's liquid glass design trend for 2025
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final double blur;
  final double opacity;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 10.0,
    this.opacity = 0.15,
    this.color,
    this.border,
    this.boxShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient ?? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (color ?? Colors.white).withOpacity(opacity),
                  (color ?? Colors.white).withOpacity(opacity * 0.5),
                ],
              ),
              borderRadius: borderRadius ?? BorderRadius.circular(20),
              border: border ?? Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A glassmorphism button with subtle animations
class GlassButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final Color? color;
  final double? width;
  final double? height;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding,
    this.borderRadius,
    this.color,
    this.width,
    this.height,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GlassContainer(
          width: widget.width,
          height: widget.height,
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          opacity: 0.2,
          color: widget.color ?? Theme.of(context).colorScheme.primary,
          child: widget.child,
        ),
      ),
    );
  }
}

/// A glassmorphism card with enhanced visual depth
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final card = GlassContainer(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      opacity: 0.15,
      blur: 15,
      color: color,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 30,
          offset: const Offset(0, 15),
          spreadRadius: -5,
        ),
      ],
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: card,
      );
    }

    return card;
  }
}

/// Gradient background with animated subtle shifts
class GlassGradientBackground extends StatelessWidget {
  final List<Color> colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final Widget? child;

  const GlassGradientBackground({
    super.key,
    required this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors,
        ),
      ),
      child: child,
    );
  }
}
