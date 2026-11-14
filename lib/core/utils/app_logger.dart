import 'dart:developer' as developer;

void logError(String message, Object error, StackTrace stackTrace) {
  developer.log(message, name: 'Lexi', error: error, stackTrace: stackTrace);
}
