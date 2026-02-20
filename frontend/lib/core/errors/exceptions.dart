/// "Standardized exceptions for the networking layer to decouple data sources from external libraries."

class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

class NetworkException implements Exception {
  final String message;

  NetworkException({required this.message});

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(
      {this.message = 'Session expired. Please login again.'});

  @override
  String toString() => message;
}
