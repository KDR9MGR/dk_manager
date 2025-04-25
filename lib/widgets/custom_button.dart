import 'package:flutter/material.dart';
import '../theme/color_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final bool useGradient;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.useGradient = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: ColorTheme.primary, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _buildButtonContent(context),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
     
      child: Ink(
        decoration: useGradient
            ? BoxDecoration(
                gradient: ColorTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: _buildButtonContent(context),
        ),
      ),
    );
  }

  Widget _buildButtonContent(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 50,
        width: 120,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: isOutlined ? ColorTheme.primary : ColorTheme.onPrimary,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: isOutlined ? ColorTheme.primary : ColorTheme.onPrimary,
    ));
  }
} 