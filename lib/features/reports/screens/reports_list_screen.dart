import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api.dart';
import '../../../core/models/report.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  List<Report> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.instance.get<List<dynamic>>(ApiConstants.reports);
      setState(() {
        _reports = res.data!
            .map((e) => Report.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Reports load error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          : RefreshIndicator(
              onRefresh: _load,
              child: _filtered.isEmpty
                  ? const Center(child: Text('No reports found'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _ReportCard(
                        report: _filtered[i],
                        onTap: () => context.push('/reports/${_filtered[i].ticker}'),
                      ),
                    ),
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
  const _ReportCard({required this.report, required this.onTap});
  final Report report;
  final VoidCallback onTap;

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
          border: Border.all(color: AppColors.border),
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
            Icon(Icons.chevron_right, size: 16, color: AppColors.dim),
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