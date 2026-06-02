import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api.dart';
import '../../../core/models/report.dart';

class ScreenerScreen extends StatefulWidget {
  const ScreenerScreen({super.key});

  @override
  State<ScreenerScreen> createState() => _ScreenerScreenState();
}

class _ScreenerScreenState extends State<ScreenerScreen> {
  List<Report> _all = [];
  bool _loading = true;
  bool _error = false;
  RatingClass? _filter; // null = all

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.instance.get<List<dynamic>>(ApiConstants.reports);
      setState(() {
        _all = res.data!
            .map((e) => Report.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
        _error = false;
      });
    } catch (e) {
      debugPrint('Screener load error: $e');
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  int _countFor(RatingClass c) => _all.where((r) => r.rclass == c).length;

  List<Report> get _filtered {
    final list = _filter == null
        ? [..._all]
        : _all.where((r) => r.rclass == _filter).toList();
    // Rank by expected return (highest first); stocks without a return estimate
    // sink to the bottom, ordered by conviction in the selected verdict.
    int votes(Report r) => switch (_filter) {
          RatingClass.buy => r.agentVotes.buy,
          RatingClass.sell => r.agentVotes.sell,
          RatingClass.hold => r.agentVotes.hold,
          null => r.agentVotes.buy,
        };
    list.sort((a, b) {
      final ra = a.expectedReturn, rb = b.expectedReturn;
      if (ra != null && rb != null && ra != rb) return rb.compareTo(ra);
      if (ra != null && rb == null) return -1;
      if (ra == null && rb != null) return 1;
      return votes(b).compareTo(votes(a));
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Screener')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2))
          : _error
              ? _ErrorState(onRetry: () {
                  setState(() => _loading = true);
                  _load();
                })
              : Column(
                  children: [
                    _FilterBar(
                      selected: _filter,
                      total: _all.length,
                      buyCount: _countFor(RatingClass.buy),
                      holdCount: _countFor(RatingClass.hold),
                      sellCount: _countFor(RatingClass.sell),
                      onSelect: (f) => setState(() => _filter = f),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.accent,
                        onRefresh: _load,
                        child: _filtered.isEmpty
                            ? ListView(
                                children: [
                                  const SizedBox(height: 120),
                                  Center(
                                    child: Text('No stocks match this filter.',
                                        style: AppText.body(size: 14, color: AppColors.muted)),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (_, i) => _ScreenerRow(
                                  report: _filtered[i],
                                  onTap: () =>
                                      context.push('/reports/${_filtered[i].ticker}'),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.total,
    required this.buyCount,
    required this.holdCount,
    required this.sellCount,
    required this.onSelect,
  });

  final RatingClass? selected;
  final int total, buyCount, holdCount, sellCount;
  final ValueChanged<RatingClass?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          _Chip(label: 'All', count: total, active: selected == null, color: AppColors.accent, onTap: () => onSelect(null)),
          const SizedBox(width: 8),
          _Chip(label: 'Buy', count: buyCount, active: selected == RatingClass.buy, color: AppColors.buy, onTap: () => onSelect(RatingClass.buy)),
          const SizedBox(width: 8),
          _Chip(label: 'Hold', count: holdCount, active: selected == RatingClass.hold, color: AppColors.hold, onTap: () => onSelect(RatingClass.hold)),
          const SizedBox(width: 8),
          _Chip(label: 'Sell', count: sellCount, active: selected == RatingClass.sell, color: AppColors.sell, onTap: () => onSelect(RatingClass.sell)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.count,
    required this.active,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : AppColors.border),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: AppText.body(
                  size: 13,
                  weight: FontWeight.w600,
                  color: active ? color : AppColors.muted),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: AppText.mono(
                  size: 11,
                  weight: FontWeight.w700,
                  color: active ? color : AppColors.dim),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Screener row ────────────────────────────────────────────────────────────

class _ScreenerRow extends StatelessWidget {
  const _ScreenerRow({required this.report, required this.onTap});
  final Report report;
  final VoidCallback onTap;

  Color get _verdictColor => switch (report.rclass) {
        RatingClass.buy => AppColors.buy,
        RatingClass.sell => AppColors.sell,
        RatingClass.hold => AppColors.hold,
      };

  @override
  Widget build(BuildContext context) {
    final v = report.agentVotes;
    final total = v.buy + v.hold + v.sell;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.companyName,
                          style: AppText.body(size: 14, weight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(report.ticker.replaceAll('.NS', ''),
                          style: AppText.mono(size: 11, color: AppColors.dim)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _verdictColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(report.rating.toUpperCase(),
                          style: AppText.mono(
                              size: 11, weight: FontWeight.w700, color: _verdictColor)),
                    ),
                    if (report.expectedReturn != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _fmtReturn(report.expectedReturn!),
                        style: AppText.fraunces(
                            size: 16,
                            weight: FontWeight.w800,
                            color: report.expectedReturn! >= 0 ? AppColors.buy : AppColors.sell),
                      ),
                      Text(
                        report.timeHorizon != null
                            ? 'est. · ${report.timeHorizon}'
                            : 'est. return',
                        style: AppText.mono(size: 9, color: AppColors.dim),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Vote bar
            if (total > 0)
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 6,
                  child: Row(children: [
                    if (v.buy > 0) Flexible(flex: v.buy, child: Container(color: AppColors.buy)),
                    if (v.hold > 0) Flexible(flex: v.hold, child: Container(color: AppColors.hold)),
                    if (v.sell > 0) Flexible(flex: v.sell, child: Container(color: AppColors.sell)),
                  ]),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                _VoteLabel(count: v.buy, label: 'Buy', color: AppColors.buy),
                const SizedBox(width: 14),
                _VoteLabel(count: v.hold, label: 'Hold', color: AppColors.hold),
                const SizedBox(width: 14),
                _VoteLabel(count: v.sell, label: 'Sell', color: AppColors.sell),
                const Spacer(),
                Text('$total agents', style: AppText.mono(size: 10, color: AppColors.dim)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _fmtReturn(double r) => '${r >= 0 ? '+' : ''}${r.toStringAsFixed(1)}%';

class _VoteLabel extends StatelessWidget {
  const _VoteLabel({required this.count, required this.label, required this.color});
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text('$count $label',
            style: AppText.mono(size: 10, weight: FontWeight.w600, color: AppColors.muted)),
      ],
    );
  }
}

// ── Error state ─────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Could not load stocks.', style: AppText.body(size: 14, color: AppColors.muted)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
