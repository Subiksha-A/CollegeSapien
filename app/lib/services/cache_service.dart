class CacheService {
  CacheService._();

  static final CacheService instance = CacheService._();

  final Map<String, dynamic> _cache = {};

  T? get<T>(String key) {
    final value = _cache[key];
    if (value is T) return value;
    return null;
  }

  void set(String key, dynamic value) => _cache[key] = value;

  void invalidate(String key) => _cache.remove(key);
}
