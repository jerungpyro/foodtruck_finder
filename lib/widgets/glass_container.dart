import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Modern 2025 container widget with clean shadows and smooth design
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final double? elevation;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.border,
    this.boxShadow,
    this.gradient,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedBorderRadius = borderRadius ?? BorderRadius.circular(AppTheme.radiusLarge);
    final resolvedColor = color ?? AppTheme.surface;

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? resolvedColor : null,
        gradient: gradient,
        borderRadius: resolvedBorderRadius,
        border: border,
        boxShadow: boxShadow ?? (elevation != null ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.08 * (elevation! / 4)),
            blurRadius: elevation! * 4,
            offset: Offset(0, elevation!),
          ),
        ] : AppTheme.cardShadow),
      ),
      child: child,
    );
  }
}

/// Modern 2025 button with smooth press animation
class GlassButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final Color? color;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final double? elevation;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding,
    this.borderRadius,
    this.color,
    this.gradient,
    this.width,
    this.height,
    this.elevation,
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
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
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(AppTheme.radiusMedium),
          color: widget.color ?? Theme.of(context).colorScheme.primary,
          gradient: widget.gradient,
          elevation: widget.elevation ?? AppTheme.elevationMedium,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Modern 2025 card with clean shadows
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final double? elevation;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.gradient,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final card = GlassContainer(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      color: color ?? AppTheme.surface,
      gradient: gradient,
      elevation: elevation ?? AppTheme.elevationLow,
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: card,
      );
    }

    return card;
  }
}

/// Gradient background for modern 2025 UI
class GlassGradientBackground extends StatelessWidget {
  final List<Color>? colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final Widget? child;

  const GlassGradientBackground({
    super.key,
    this.colors,
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
          colors: colors ?? AppTheme.backgroundGradient,
        ),
      ),
      child: child,
    );
  }
}
