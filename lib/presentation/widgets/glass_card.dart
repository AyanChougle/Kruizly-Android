import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? accentColor;
  final double blur;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 20,
    this.backgroundColor,
    this.borderColor,
    this.accentColor,
    this.blur = 0.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    );

    final effectiveAccent = accentColor ?? AppColors.primary;

    Widget content = Container(
      padding: padding ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark
                ? Colors.black.withValues(alpha: 0.38)
                : Colors.white.withValues(alpha: 0.94)),
        borderRadius: BorderRadius.circular(borderRadius),
        // Liquid glass gradient with subtle colored accent sheen
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  effectiveAccent.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.04),
                  Colors.black.withValues(alpha: 0.25),
                ],
                stops: const [0.0, 0.45, 1.0],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.96),
                  effectiveAccent.withValues(alpha: 0.04),
                  Colors.white.withValues(alpha: 0.93),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
        border: Border.all(
          color: borderColor ??
              (isDark
                  ? effectiveAccent.withValues(alpha: 0.22)
                  : effectiveAccent.withValues(alpha: 0.18)),
          width: 0.8,
        ),
        boxShadow: [
          // Ambient liquid colored glow
          BoxShadow(
            color: isDark
                ? effectiveAccent.withValues(alpha: 0.10)
                : const Color(0x0E0F172A),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0x080F172A),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (blur > 0) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    } else {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: effectiveAccent.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          child: content,
        ),
      );
    }

    return content;
  }
}
