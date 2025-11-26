import 'package:logger/logger.dart';

/// Global logger instance
final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 50,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

/// Quick access methods
void logDebug(String message) => appLogger.d(message);
void logInfo(String message) => appLogger.i(message);
void logWarning(String message) => appLogger.w(message);
void logError(String message, [dynamic error, StackTrace? stackTrace]) {
  appLogger.e(message, error: error, stackTrace: stackTrace);
}
