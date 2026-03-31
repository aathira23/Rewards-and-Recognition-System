/// In-memory cache interceptor for Dio GET requests.
///
/// Caches successful GET responses for a configurable TTL so that rapid
/// repeated fetches for the same endpoint (e.g. dashboard, catalog, badges)
/// are served instantly from memory instead of hitting the backend every time.
///
/// - Only GET requests are cached.
/// - POST / PUT / DELETE requests automatically invalidate cache entries whose
///   path prefix matches the mutating request (e.g. POST /catalog/redeem
///   clears all cached /catalog/* responses).
/// - Individual entries expire after [defaultTtl] (default 5 minutes).
/// - The entire cache can be flushed via [CacheInterceptor.clearAll].

import 'package:dio/dio.dart';

class _CacheEntry {
  final Response response;
  final DateTime expiresAt;

  _CacheEntry(this.response, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class CacheInterceptor extends Interceptor {
  /// Default time-to-live for cached responses.
  final Duration defaultTtl;

  /// Maximum number of cached responses to keep in memory.
  final int maxEntries;

  final Map<String, _CacheEntry> _cache = {};

  CacheInterceptor({
    this.defaultTtl = const Duration(minutes: 5),
    this.maxEntries = 200,
  });

  /// Build a unique key from the request path + sorted query parameters.
  String _keyFor(RequestOptions options) {
    final uri = options.uri;
    // Include path and sorted query params for deterministic keys.
    final sortedQuery = Map.fromEntries(
      uri.queryParameters.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    );
    return '${uri.path}?${Uri(queryParameters: sortedQuery.isEmpty ? null : sortedQuery).query}';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Only cache GET requests.
    if (options.method.toUpperCase() != 'GET') {
      // Mutating requests: invalidate any cached entries whose path matches.
      _invalidateByPrefix(options.uri.path);
      handler.next(options);
      return;
    }

    final key = _keyFor(options);
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) {
      // Cache HIT — resolve immediately without a network call.
      return handler.resolve(entry.response, true);
    }

    // Cache MISS — let the request continue.
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Only cache successful GET responses.
    if (response.requestOptions.method.toUpperCase() == 'GET' &&
        response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      final key = _keyFor(response.requestOptions);

      // Evict oldest entries when at capacity.
      if (_cache.length >= maxEntries) {
        _cache.remove(_cache.keys.first);
      }

      _cache[key] = _CacheEntry(
        response,
        DateTime.now().add(defaultTtl),
      );
    }
    handler.next(response);
  }

  /// Remove all entries whose key starts with any prefix derived from [path].
  /// Example: POST /catalog/redeem → clears all /catalog* entries.
  void _invalidateByPrefix(String path) {
    // Use the first two path segments as the invalidation prefix.
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return;
    final prefix = '/${segments.first}';
    _cache.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// Clear the entire cache (e.g. on logout).
  void clearAll() => _cache.clear();
}
