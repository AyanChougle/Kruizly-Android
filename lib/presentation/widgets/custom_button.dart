import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.height = 52,
    this.borderRadius = 12,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final defaultAccent = isDark ? AppColors.primaryLight : AppColors.primary;
    final effectiveTextColor = textColor ?? (isOutlined ? defaultAccent : Colors.white);
    final effectiveBorderColor = backgroundColor ?? defaultAccent;
    final effectiveFontSize = height <= 40 ? 13.0 : 15.0;

    if (isOutlined) {
      return Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: effectiveBorderColor,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: height <= 40 ? 18 : 22,
                      height: height <= 40 ? 18 : 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: effectiveTextColor,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: height <= 40 ? 15 : 18, color: effectiveTextColor),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: effectiveFontSize,
                              fontWeight: FontWeight.w700,
                              color: effectiveTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: onPressed == null || isLoading
            ? null
            : AppColors.primaryGradient,
        color: onPressed == null || isLoading
            ? AppColors.surfaceElevated
            : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: onPressed == null || isLoading
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor ?? Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
