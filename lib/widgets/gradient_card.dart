import 'package:flutter/material.dart';
import '../theme/color_theme.dart';

class GradientCard extends StatelessWidget {
  final Widget child;
  final LinearGradient? gradient;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double elevation;
  final bool hasShadow;

  const GradientCard({
    Key? key,
    required this.child,
    this.gradient,
    this.borderRadius = 15.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.symmetric(vertical: 8.0),
    this.elevation = 4.0,
    this.hasShadow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient ?? ColorTheme.primaryGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }

  factory GradientCard.surface({
    required Widget child,
    double borderRadius = 15.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(vertical: 8.0),
    double elevation = 4.0,
  }) {
    return GradientCard(
      gradient: ColorTheme.surfaceGradient,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      elevation: elevation,
      child: child,
    );
  }

  factory GradientCard.accent({
    required Widget child,
    double borderRadius = 15.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(vertical: 8.0),
    double elevation = 4.0,
  }) {
    return GradientCard(
      gradient: ColorTheme.accentGradient,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      elevation: elevation,
      child: child,
    );
  }
} 