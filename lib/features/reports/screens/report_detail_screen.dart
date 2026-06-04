import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api.dart';
import '../../../core/models/report.dart';
import '../../../core/models/report_detail.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/featured_provider.dart';
import '../../../core/providers/viewed_today_provider.dart';
import '../../../core/widgets/login_gate.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  const ReportDetailScreen({super.key, required this.ticker});
  final String ticker;

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  ReportDetail? _report;
  bool _loading = true;
  bool _notFound = false;
  bool _started = false; // ensures the report is fetched at most once, lazily

  Future<void> _load() async {
    try {
      final res = await ApiService.instance.get<Map<String, dynamic>>(
        '${ApiConstants.reports}/${Uri.encodeComponent(widget.ticker)}',
      );
      if (!mounted) return;
      setState(() {
        _report = ReportDetail.fromJson(res.data!);
        _loading = false;
      });
      // Record the view (best-effort) so it surfaces under "Recently viewed".
      // No-op for guests; we use the report's own ticker so it matches the
      // reports list when the dashboard joins them.
      recordReportView(ref, _report!.ticker);
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _notFound = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isGuest = user == null || user.isGuest;

    // Guests may only open the report of the day; anything else is gated. This
    // is the single chokepoint, so deep links / restored back-stacks are covered
    // too — not just taps from the list.
    if (isGuest) {
      final featuredAsync = ref.watch(featuredTickerProvider);
      if (featuredAsync.isLoading) {
        return _LoadingSkeleton(ticker: widget.ticker);
      }
      if (widget.ticker != featuredAsync.valueOrNull) {
        return _GatedReport(ticker: widget.ticker);
      }
    }

    // Allowed — fetch once (deferred until we know access is granted, so a gated
    // report never triggers a network call).
    if (!_started) {
      _started = true;
      _load();
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _loading
          ? _LoadingSkeleton(ticker: widget.ticker)
          : _notFound || _report == null
              ? _NotFound(ticker: widget.ticker)
              : _ReportBody(report: _report!),
    );
  }
}

// ── Login gate (guest opened a non-free report) ─────────────────────────────────

class _GatedReport extends StatelessWidget {
  const _GatedReport({required this.ticker});
  final String ticker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(color: AppColors.text),
        title: Text(
          ticker.replaceAll('.NS', ''),
          style: AppText.fraunces(size: 17, weight: FontWeight.w800),
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: LoginGate(
          icon: Icons.lock_outline,
          title: 'Sign in to read this report',
          message:
              "Today's free report is on the Reports tab. Sign in or create a free "
              'account to unlock this report — and every other one.',
        ),
      ),
    );
  }
}

// ── Full report body ──────────────────────────────────────────────────────────

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});
  final ReportDetail report;

  Color get _verdictColor => switch (report.rclass) {
    RatingClass.buy  => AppColors.buy,
    RatingClass.sell => AppColors.sell,
    RatingClass.hold => AppColors.hold,
  };

  List<String> get _bullPoints => report.sections
      .where((s) => RegExp(r'bull|buy|positive|strong', caseSensitive: false)
          .hasMatch(s.summary?.verdict ?? ''))
      .expand<String>((s) => s.summary?.bullets.take(1) ?? <String>[])
      .take(2)
      .toList();

  List<String> get _bearPoints => report.sections
      .where((s) => RegExp(r'bear|sell|negative|weak', caseSensitive: false)
          .hasMatch(s.summary?.verdict ?? ''))
      .expand<String>((s) => s.summary?.bullets.take(1) ?? <String>[])
      .take(2)
      .toList();

  @override
  Widget build(BuildContext context) {
    final buy  = report.agentVotes.buy;
    final hold = report.agentVotes.hold;
    final sell = report.agentVotes.sell;
    final total = (buy + hold + sell).toDouble();

    return CustomScrollView(
      slivers: [
        // ── App bar ──
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          leading: const BackButton(color: AppColors.text),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.ticker.replaceAll('.NS', ''),
                style: AppText.fraunces(size: 17, weight: FontWeight.w800),
              ),
              Text(report.companyName, style: AppText.body(size: 11, color: AppColors.dim), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _verdictColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white54, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(report.rating.toUpperCase(), style: AppText.mono(size: 11, weight: FontWeight.w700, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Meta row ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Text('Report · ', style: AppText.mono(size: 10, color: AppColors.dim)),
                    Text(report.date, style: AppText.mono(size: 10, weight: FontWeight.w700, color: AppColors.text)),
                    const Spacer(),
                    Text('12 AI Agents · Conflict-Free', style: AppText.mono(size: 10, color: AppColors.dim)),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Divider(height: 1, color: AppColors.border),
              ),

              // ── Summary ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(report.summary, style: AppText.body(size: 14, color: AppColors.muted, height: 1.5)),
              ),

              // ── Price target ──
              if (report.priceTarget != null || report.expectedReturn != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _TargetCard(report: report),
                ),

              // ── Consensus panel ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: _ConsensusPanel(
                  buy: buy, hold: hold, sell: sell, total: total,
                  bullPoints: _bullPoints, bearPoints: _bearPoints,
                ),
              ),

              // ── Sections ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text('Agent Findings', style: AppText.fraunces(size: 16, weight: FontWeight.w700)),
              ),
              ...report.sections
                  .where((s) => s.summary != null)
                  .map((s) => _SectionCard(section: s)),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Consensus panel ───────────────────────────────────────────────────────────

class _ConsensusPanel extends StatelessWidget {
  const _ConsensusPanel({
    required this.buy, required this.hold, required this.sell, required this.total,
    required this.bullPoints, required this.bearPoints,
  });
  final int buy, hold, sell;
  final double total;
  final List<String> bullPoints, bearPoints;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.text,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('12-AGENT CONSENSUS', style: AppText.mono(size: 9, color: Colors.white54)),
              Row(children: [
                Text('$buy BUY', style: AppText.mono(size: 11, weight: FontWeight.w700, color: const Color(0xFF4ADE80))),
                Text(' · ', style: AppText.mono(size: 11, color: Colors.white38)),
                Text('$hold HOLD', style: AppText.mono(size: 11, weight: FontWeight.w700, color: const Color(0xFFFACC15))),
                Text(' · ', style: AppText.mono(size: 11, color: Colors.white38)),
                Text('$sell SELL', style: AppText.mono(size: 11, weight: FontWeight.w700, color: const Color(0xFFF87171))),
              ]),
            ],
          ),
          const SizedBox(height: 12),

          // Vote bar
          if (total > 0) ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(children: [
                if (buy > 0) Flexible(flex: buy, child: Container(color: AppColors.buy)),
                if (buy > 0 && (hold > 0 || sell > 0)) const SizedBox(width: 2),
                if (hold > 0) Flexible(flex: hold, child: Container(color: AppColors.hold)),
                if (hold > 0 && sell > 0) const SizedBox(width: 2),
                if (sell > 0) Flexible(flex: sell, child: Container(color: AppColors.sell)),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // Bull / Bear
          if (bullPoints.isNotEmpty || bearPoints.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _CaseColumn(title: 'BULL CASE', points: bullPoints, color: const Color(0xFF4ADE80))),
                  Container(width: 1, color: Colors.white12),
                  Expanded(child: _CaseColumn(title: 'BEAR CASE', points: bearPoints, color: const Color(0xFFF87171))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CaseColumn extends StatelessWidget {
  const _CaseColumn({required this.title, required this.points, required this.color});
  final String title;
  final List<String> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.03),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.mono(size: 9, weight: FontWeight.w700, color: color)),
          const SizedBox(height: 8),
          if (points.isEmpty)
            Text('No signals', style: AppText.body(size: 12, color: Colors.white38))
          else
            ...points.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 6),
                    child: Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  ),
                  Expanded(child: Text(p, style: AppText.body(size: 12, color: Colors.white70, height: 1.4))),
                ],
              ),
            )),
        ],
      ),
    );
  }
}

// ── Price target card ─────────────────────────────────────────────────────────

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.report});
  final ReportDetail report;

  @override
  Widget build(BuildContext context) {
    final ret = report.expectedReturn;
    final cells = <Widget>[
      if (report.priceTarget != null) _Stat(label: 'Target', value: _money(report.priceTarget!)),
      if (report.entryPrice != null) _Stat(label: 'Entry', value: _money(report.entryPrice!)),
      if (ret != null)
        _Stat(
          label: 'Est. return',
          value: '${ret >= 0 ? '+' : ''}${ret.toStringAsFixed(1)}%',
          valueColor: ret >= 0 ? AppColors.buy : AppColors.sell,
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('PRICE TARGET', style: AppText.mono(size: 10, color: AppColors.dim)),
              const Spacer(),
              if (report.timeHorizon != null)
                Text(report.timeHorizon!, style: AppText.mono(size: 10, color: AppColors.dim)),
            ],
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < cells.length; i++) ...[
                  if (i > 0) Container(width: 1, color: AppColors.border),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          left: i == 0 ? 0 : 14, right: i == cells.length - 1 ? 0 : 14),
                      child: cells[i],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (report.expectedReturnAnnualized != null) ...[
            const SizedBox(height: 12),
            Text('${report.expectedReturnAnnualized!.toStringAsFixed(1)}% annualized',
                style: AppText.mono(size: 11, color: AppColors.muted)),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.body(size: 12, color: AppColors.muted)),
        const SizedBox(height: 3),
        Text(value,
            style: AppText.fraunces(size: 18, weight: FontWeight.w700, color: valueColor ?? AppColors.text)),
      ],
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatefulWidget {
  const _SectionCard({required this.section});
  final ReportSection section;

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _expanded = false;

  Color _decisionColor(String? d) => switch (d) {
    'Bullish' => AppColors.buy,
    'Bearish' => AppColors.sell,
    _         => AppColors.hold,
  };

  @override
  Widget build(BuildContext context) {
    final summary = widget.section.summary!;
    final decisionColor = _decisionColor(summary.decision);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(widget.section.label, style: AppText.body(size: 14, weight: FontWeight.w600)),
                    ),
                    if (summary.decision != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: decisionColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(summary.decision!, style: AppText.mono(size: 10, weight: FontWeight.w700, color: decisionColor)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: AppColors.dim),
                  ],
                ),
              ),

              // Verdict summary (always visible)
              if (summary.verdict.isNotEmpty) Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Text(summary.verdict, style: AppText.body(size: 13, color: AppColors.muted, height: 1.4)),
              ),

              // Expanded bullets
              if (_expanded && summary.bullets.isNotEmpty) ...[
                const Divider(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: summary.bullets.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6, right: 8),
                            child: Container(width: 4, height: 4, decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                          ),
                          Expanded(child: Text(b, style: AppText.body(size: 13, color: AppColors.text, height: 1.45))),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Loading skeleton ──────────────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton({required this.ticker});
  final String ticker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: const BackButton(color: AppColors.text),
        title: Text(ticker.replaceAll('.NS', ''), style: AppText.fraunces(size: 17, weight: FontWeight.w800)),
      ),
      body: const Center(
        child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
      ),
    );
  }
}

// ── Not found ─────────────────────────────────────────────────────────────────

class _NotFound extends StatelessWidget {
  const _NotFound({required this.ticker});
  final String ticker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: const BackButton(color: AppColors.text),
        title: Text(ticker, style: AppText.fraunces(size: 17)),
      ),
      body: Center(
        child: Text(
          'Report not found for $ticker',
          style: AppText.body(size: 14, color: AppColors.muted),
        ),
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

String _money(double v) {
  final isInt = v == v.roundToDouble();
  final s = isInt ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  final parts = s.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  final grouped = buf.toString();
  return '₹${parts.length > 1 ? '$grouped.${parts[1]}' : grouped}';
}