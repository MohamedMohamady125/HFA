import 'package:flutter/material.dart';
import '../services/offline/offline_repository.dart';
import '../theme/app_theme.dart';

/// Consistent success / saved-offline / error feedback across the app.
class AppFeedback {
  AppFeedback._();

  static void showSuccess(BuildContext context, String message) =>
      _show(context, message, AppColors.success, Icons.check_circle_rounded);

  /// Shown when a write was queued because the device is offline.
  static void showQueued(BuildContext context, [String? message]) => _show(
        context,
        message ?? 'Saved on this device — will sync when you\'re back online',
        AppColors.warning,
        Icons.cloud_upload_rounded,
      );

  static void showError(BuildContext context, Object error, {String? fallback}) => _show(
        context,
        OfflineRepository.errorMessage(error,
            fallback: fallback ?? 'Something went wrong. Please try again.'),
        AppColors.error,
        Icons.error_outline_rounded,
      );

  /// Convenience: show success or queued based on a WriteResult.
  static void showWriteResult(BuildContext context, WriteResult result,
      {String successMessage = 'Saved'}) {
    if (result.synced) {
      showSuccess(context, successMessage);
    } else {
      showQueued(context);
    }
  }

  static void _show(BuildContext context, String message, Color color, IconData icon) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ));
  }
}
