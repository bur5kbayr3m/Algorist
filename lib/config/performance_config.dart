import 'package:flutter/foundation.dart';

/// Performance Configuration
/// Bu dosya uygulamanın performans ayarlarını içerir
class PerformanceConfig {
  // Debug modda logları göster
  static const bool enableDetailedLogs = kDebugMode;

  // Database query timeout
  static const Duration databaseTimeout = Duration(seconds: 5);

  // Image cache configuration
  static const int imageCacheSize = 100; // MB

  // List pagination
  static const int itemsPerPage = 20;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);

  // Network timeouts
  static const Duration networkTimeout = Duration(seconds: 10);
}
