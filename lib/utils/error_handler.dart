import 'package:flutter/material.dart';
import '../utils/app_logger.dart';

class ErrorHandler {
  static String getLocalizedMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();

      if (message.contains('SocketException')) {
        return 'İnternet bağlantısı kontrol edin';
      }
      if (message.contains('TimeoutException')) {
        return 'İstek zaman aşımına uğradı. Tekrar deneyin.';
      }
      if (message.contains('FormatException')) {
        return 'Veri işlenirken bir hata oluştu';
      }
      if (message.contains('authentication')) {
        return 'Kimlik doğrulama başarısız. Lütfen tekrar giriş yapın.';
      }
      if (message.contains('not found')) {
        return 'İstenen veri bulunamadı';
      }
    }

    return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }

  static void showError(BuildContext context, dynamic error,
      {VoidCallback? onRetry}) {
    final message = getLocalizedMessage(error);
    AppLogger.error('Error: ${error.toString()}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Tekrar',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
