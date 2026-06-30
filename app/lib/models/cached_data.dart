class CachedData<T> {
  final T data;
  final DateTime cachedAt;
  final Duration ttl;

  CachedData({
    required this.data,
    required this.ttl,
    DateTime? cachedAt,
  }) : cachedAt = cachedAt ?? DateTime.now();

  bool get isExpired {
    final now = DateTime.now();
    final expiry = cachedAt.add(ttl);
    return now.isAfter(expiry);
  }

  bool get isValid => !isExpired;
}
