import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api.dart';
import '../../../core/models/report.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/featured_provider.dart';

class ReportsListScreen extends ConsumerStatefulWidget {
  const ReportsListScreen({super.key});

  @override
  ConsumerState<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends ConsumerState<ReportsListScreen> {
  List<Report> _reports = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_loading) setState(() { _loading = true; _error = false; });
    try {
      final res = await ApiService.instance.get<List<dynamic>>(ApiConstants.reports);
      if (!mounted) return;
      setState(() {
        _reports = res.data!
            .map((e) => Report.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
        _error = false;
      });
    } catch (e) {
      debugPrint('Reports load error: $e');
      if (!mounted) return;
      setState(() { _loading = false; _error = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isGuest = user == null || user.isGuest;
    // The single report a guest may open for free. Null while loading or if it
    // can't be resolved — in which case nothing is unlocked (all cards gated).
    final featuredTicker = ref.watch(featuredTickerProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Reports'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (q) => setState(() => _query = q),
              decoration: InputDecoration(
                hintText: 'Search stocks…',
                hintStyle: AppText.body(size: 14, color: AppColors.dim),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.dim),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? _Skeleton()
          : _error
              ? _ErrorState(onRetry: _load)
              : Column(
                  children: [
                    if (isGuest) const _GuestBanner(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: _filtered.isEmpty
                            ? const Center(child: Text('No reports found'))
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (_, i) {
                                  final r = _filtered[i];
                                  final freeToday = isGuest && r.ticker == featuredTicker;
                                  return _ReportCard(
                                    report: r,
                                    // Guests may open only the report of the day; the rest
                                    // are gated. Signed-in users see everything unlocked.
                                    locked: isGuest && r.ticker != featuredTicker,
                                    freeToday: freeToday,
                                    onTap: () => context.push('/reports/${r.ticker}'),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _query = '';

  List<Report> get _filtered {
    if (_query.trim().isEmpty) return _reports;
    final q = _query.trim().toUpperCase();
    return _reports
        .where((r) =>
            r.ticker.toUpperCase().contains(q) ||
            r.companyName.toUpperCase().contains(q))
        .toList();
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.onTap,
    this.locked = false,
    this.freeToday = false,
  });
  final Report report;
  final VoidCallback onTap;
  final bool locked;    // guest, and this isn't the report of the day
  final bool freeToday; // guest, and this IS the free report of the day

  Color get _verdictColor => switch (report.rclass) {
    RatingClass.buy  => AppColors.buy,
    RatingClass.sell => AppColors.sell,
    RatingClass.hold => AppColors.hold,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          // The free pick is highlighted; everything else uses the default border.
          border: Border.all(color: freeToday ? AppColors.accent : AppColors.border),
        ),
        child: Row(
          children: [
            // Verdict circle
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _verdictColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(report.arrow, style: TextStyle(fontSize: 16, color: _verdictColor)),
              ),
            ),
            const SizedBox(width: 12),
            // Company info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.companyName, style: AppText.body(size: 14, weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${report.ticker.replaceAll('.NS', '')} · ${report.date}',
                    style: AppText.mono(size: 11, color: AppColors.dim),
                  ),
                  if (freeToday) ...[
                    const SizedBox(height: 6),
                    _Tag(text: "TODAY'S FREE REPORT", color: AppColors.accent),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Verdict pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _verdictColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                report.rating.toUpperCase(),
                style: AppText.mono(size: 11, weight: FontWeight.w700, color: _verdictColor),
              ),
            ),
            const SizedBox(width: 6),
            // Locked reports show a lock; openable ones show the usual chevron.
            Icon(locked ? Icons.lock_outline : Icons.chevron_right, size: 16, color: AppColors.dim),
          ],
        ),
      ),
    );
  }
}

/// Small uppercase pill used for the "free report" tag.
class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: AppText.mono(size: 9, weight: FontWeight.w700, color: color)),
    );
  }
}

/// Slim banner shown to guests above the reports list, explaining the free pick.
class _GuestBanner extends StatelessWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_open_outlined, size: 18, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Today's report is free to read. Sign in to unlock every report.",
              style: AppText.body(size: 12.5, color: AppColors.muted, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.dim),
            const SizedBox(height: 14),
            Text("Couldn't load reports",
                style: AppText.fraunces(size: 18, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: AppText.body(size: 14, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Container(
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const _ShimmerRow(),
      ),
    );
  }
}

class _ShimmerRow extends StatefulWidget {
  const _ShimmerRow();
  @override
  State<_ShimmerRow> createState() => _ShimmerRowState();
}

class _ShimmerRowState extends State<_ShimmerRow> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.s2, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(height: 13, width: 140, decoration: BoxDecoration(color: AppColors.s2, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 6),
              Container(height: 10, width: 80, decoration: BoxDecoration(color: AppColors.s2, borderRadius: BorderRadius.circular(4))),
            ])),
            Container(height: 24, width: 48, decoration: BoxDecoration(color: AppColors.s2, borderRadius: BorderRadius.circular(20))),
          ]),
        ),
      ),
    );
  }
}