// exceptions.dart
// Raw exceptions thrown by datasources.
// Caught in repository implementations and mapped to Failures.

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
}

class ServerException implements Exception {
  final String message;
  final int?   statusCode;
  const ServerException(this.message, {this.statusCode});
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
}
