import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Reports that could not be delivered yet. Persisted so they survive restarts.
/// ponytail: shared_preferences JSON list; move to sqlite if queues get large.
class OutboxService {
  static const String _key = 'dinig_outbox';

  /// Automatic retries stop here; [flush] with `force: true` tries again.
  static const int maxAttempts = 10;

  static bool _flushing = false;

  static Future<List<Map<String, dynamic>>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items));
  }

  static Future<int> pendingCount() async => (await _load()).length;

  static Future<void> add(Map<String, dynamic> entry) async {
    final items = await _load();
    items.add({...entry, 'attempts': 0});
    await _save(items);
  }

  /// Runs [send] for each queued entry. Delivered entries are removed, failed
  /// ones keep their place with one more attempt. Returns the delivered count.
  static Future<int> flush(
    Future<bool> Function(Map<String, dynamic> entry) send, {
    bool force = false,
  }) async {
    if (_flushing) return 0;
    _flushing = true;
    try {
      final items = await _load();
      final remaining = <Map<String, dynamic>>[];
      var delivered = 0;
      for (final item in items) {
        final attempts = item['attempts'] as int? ?? 0;
        if (attempts >= maxAttempts && !force) {
          remaining.add(item);
          continue;
        }
        bool ok;
        try {
          ok = await send(item);
        } catch (_) {
          ok = false;
        }
        if (ok) {
          delivered++;
        } else {
          remaining.add({...item, 'attempts': attempts + 1});
        }
      }
      await _save(remaining);
      return delivered;
    } finally {
      _flushing = false;
    }
  }
}
