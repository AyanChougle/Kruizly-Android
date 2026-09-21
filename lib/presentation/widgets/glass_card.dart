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
  final double blur;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 16,
    this.backgroundColor,
    this.borderColor,
    this.blur = 0.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    );

    Widget content = Container(
      padding: padding ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white),
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.02),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF8FAFC),
                ],
              ),
        border: Border.all(
          color: borderColor ?? (isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.lightBorder),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0x120F172A),
            blurRadius: isDark ? 18 : 12,
            offset: const Offset(0, 4),
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
          splashColor: AppColors.primary.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          child: content,
        ),
      );
    }

    return content;
  }
}
