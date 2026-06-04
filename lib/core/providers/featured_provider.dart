import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report.dart';
import '../services/api_service.dart';
import '../constants/api.dart';

/// Today's free "report of the day" — the single report a guest can open
/// without signing in. Backed by `GET /reports/featured`, which the backend
/// resolves (admin-pinned for the day, else the most recent report).
///
/// Returns null if it can't be resolved (offline / no reports). Callers treat
/// null as "nothing is free", so cards stay gated rather than wrongly unlock,
/// and the Home highlight simply hides itself.
final featuredReportProvider = FutureProvider<Report?>((ref) async {
  try {
    final res = await ApiService.instance
        .get<Map<String, dynamic>>(ApiConstants.featured);
    final data = res.data;
    return data == null ? null : Report.fromJson(data);
  } catch (_) {
    return null;
  }
});

/// Just the featured ticker, derived from [featuredReportProvider]. Preserves
/// the loading/error state so gating screens can wait before deciding.
final featuredTickerProvider = Provider<AsyncValue<String?>>((ref) {
  return ref.watch(featuredReportProvider).whenData((r) => r?.ticker);
});
