import 'package:flutter/material.dart';

enum SnackBarType { success, error, info, warning }

void showSnackBar(
  BuildContext context,
  String message, {
  SnackBarType type = SnackBarType.info,
  Duration duration = const Duration(seconds: 4),
  SnackBarAction? action,
  bool showCloseIcon = true,
  VoidCallback? onVisible,
}) {
  // Dismiss any existing snackbars
  ScaffoldMessenger.of(context).hideCurrentSnackBar();

  // Define colors and icons based on type
  final Map<SnackBarType, _SnackBarStyle> styles = {
    SnackBarType.success: _SnackBarStyle(
      backgroundColor: Colors.green.shade800,
      iconData: Icons.check_circle_outline,
      borderColor: Colors.green.shade600,
      lightColor: Colors.green.shade700,
    ),
    SnackBarType.error: _SnackBarStyle(
      backgroundColor: Colors.red.shade800,
      iconData: Icons.error_outline,
      borderColor: Colors.red.shade600,
      lightColor: Colors.red.shade700,
    ),
    SnackBarType.info: _SnackBarStyle(
      backgroundColor: Colors.blue.shade800,
      iconData: Icons.info_outline,
      borderColor: Colors.blue.shade600,
      lightColor: Colors.blue.shade700,
    ),
    SnackBarType.warning: _SnackBarStyle(
      backgroundColor: Colors.orange.shade800,
      iconData: Icons.warning_amber_outlined,
      borderColor: Colors.orange.shade600,
      lightColor: Colors.orange.shade700,
    ),
  };

  final style = styles[type]!;
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  final snackBar = SnackBar(
    content: Row(
      children: [
        // Icon with subtle glow effect
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: style.borderColor.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(style.iconData, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        // Message with potential overflow handling
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
    backgroundColor:
        isDarkMode
            ? style.backgroundColor.withOpacity(0.95)
            : style.backgroundColor,
    duration: duration,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: style.borderColor, width: 1),
    ),
    action:
        showCloseIcon
            ? SnackBarAction(
              label: 'DISMISS',
              textColor: Colors.white.withOpacity(0.8),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            )
            : action,
    elevation: 6,
    margin: const EdgeInsets.all(12),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    onVisible: onVisible,
    dismissDirection: DismissDirection.horizontal,
    clipBehavior: Clip.hardEdge,
  );

  // Show the snackbar with animation
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

// Helper class to organize style properties
class _SnackBarStyle {
  final Color backgroundColor;
  final IconData iconData;
  final Color borderColor;
  final Color lightColor;

  _SnackBarStyle({
    required this.backgroundColor,
    required this.iconData,
    required this.borderColor,
    required this.lightColor,
  });
}

// Extension method for easier calling from anywhere
extension SnackBarExtension on BuildContext {
  void showSuccessSnackBar(
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    showSnackBar(
      this,
      message,
      type: SnackBarType.success,
      duration: duration ?? const Duration(seconds: 4),
      action: action,
    );
  }

  void showErrorSnackBar(
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    showSnackBar(
      this,
      message,
      type: SnackBarType.error,
      duration: duration ?? const Duration(seconds: 4),
      action: action,
    );
  }

  void showInfoSnackBar(
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    showSnackBar(
      this,
      message,
      type: SnackBarType.info,
      duration: duration ?? const Duration(seconds: 4),
      action: action,
    );
  }

  void showWarningSnackBar(
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    showSnackBar(
      this,
      message,
      type: SnackBarType.warning,
      duration: duration ?? const Duration(seconds: 4),
      action: action,
    );
  }
}
