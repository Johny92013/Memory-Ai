/// App-weite Ausnahme mit lesbarer Meldung und optionalem Fehlercode.
class AppException implements Exception {
  const AppException({required this.message, this.code, this.originalError});

  final String message;
  final String? code;
  final Object? originalError;

  @override
  String toString() => 'AppException($code): $message';
}
