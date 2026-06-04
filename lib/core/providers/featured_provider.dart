import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../constants/api.dart';

/// The ticker of today's free "report of the day" — the single report a guest
/// can open without signing in. Backed by `GET /reports/featured`, which the
/// backend resolves (admin-pinned for the day, else the most recent report).
///
/// Returns null if it can't be resolved (offline / no reports); callers treat
/// null as "nothing is free", so every card stays gated rather than wrongly
/// unlocking one.
final featuredTickerProvider = FutureProvider<String?>((ref) async {
  try {
    final res = await ApiService.instance
        .get<Map<String, dynamic>>(ApiConstants.featured);
    return res.data?['ticker'] as String?;
  } catch (_) {
    return null;
  }
});
