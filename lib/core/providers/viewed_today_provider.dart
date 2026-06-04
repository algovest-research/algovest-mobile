import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report.dart';
import '../services/api_service.dart';
import '../constants/api.dart';
import 'auth_provider.dart';

/// Reports the signed-in user has opened today (IST), most-recent-first, for the
/// dashboard's "Recently viewed" section.
///
/// The backend's `GET /users/me/viewed-today` returns only tickers, so we join
/// them against the full reports list to get something renderable. Tickers
/// without a matching report (e.g. a since-removed report) are dropped.
///
/// Account-scoped, so guests get an empty list. Invalidated after a view is
/// recorded (see report detail) so the dashboard refreshes on the way back.
final viewedTodayProvider = FutureProvider<List<Report>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.isGuest) return const [];

  final viewedRes = await ApiService.instance
      .get<Map<String, dynamic>>(ApiConstants.myViewedToday);
  final tickers = (viewedRes.data?['tickers'] as List<dynamic>? ?? const [])
      .map((e) => e as String)
      .toList();
  if (tickers.isEmpty) return const [];

  final reportsRes =
      await ApiService.instance.get<List<dynamic>>(ApiConstants.reports);
  final byTicker = <String, Report>{
    for (final e in reportsRes.data ?? const [])
      (e as Map<String, dynamic>)['ticker'] as String:
          Report.fromJson(e),
  };

  // Preserve the order viewed-today returns (newest first), dropping any ticker
  // we can't resolve to a report.
  return [
    for (final t in tickers)
      if (byTicker[t] != null) byTicker[t]!,
  ];
});

/// Records that the current user opened [ticker] today, consuming one daily view
/// (revisiting the same ticker the same day is free server-side). Best-effort:
/// failures are swallowed since this only feeds the recently-viewed section and
/// must never block reading a report. No-op for guests.
Future<void> recordReportView(WidgetRef ref, String ticker) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.isGuest) return;
  try {
    await ApiService.instance
        .post<Map<String, dynamic>>(ApiConstants.consumeView, data: {'ticker': ticker});
    ref.invalidate(viewedTodayProvider);
  } catch (_) {
    // best-effort — secondary feature, never surface an error here
  }
}
