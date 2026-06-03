import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/requests_provider.dart';
import '../../../core/models/stock_request.dart';
import '../../../core/widgets/app_logo.dart';
import '../widgets/request_analysis_sheet.dart';

const _popularTickers = ['RELIANCE', 'TCS', 'HDFC', 'INFY', 'ICICIBANK', 'ADANIENT'];

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand logo
                    const AppLogo(height: 26),
                    const SizedBox(height: 20),

                    // Welcome hero — brand positioning
                    const _WelcomeHero(),
                    const SizedBox(height: 24),

                    // Greeting
                    const _Greeting(),
                    const SizedBox(height: 16),

                    // Analyse any Nifty 500 stock
                    _AnalyseCard(),
                    const SizedBox(height: 16),

                    // Stats row
                    _StatsRow(),
                    const SizedBox(height: 20),

                    // Your analysis requests (hidden for guests / when empty)
                    const _YourRequests(),

                    Text('Recently Viewed', style: AppText.fraunces(size: 17, weight: FontWeight.w700)),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // TODO: recently viewed list
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _EmptyRecentlyViewed(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Welcome hero ──────────────────────────────────────────────────────────────

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.text,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 12, color: Colors.white70),
                const SizedBox(width: 6),
                Text('AI-POWERED · 12 AGENTS',
                    style: AppText.mono(size: 10, weight: FontWeight.w600, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Headline
          Text(
            'Clarity on every\nIndian stock.',
            style: AppText.fraunces(size: 26, weight: FontWeight.w700, color: Colors.white, height: 1.1),
          ),
          const SizedBox(height: 10),

          // Sub-copy
          Text(
            '12 AI agents debate the bull and bear case to deliver a clear verdict on any Nifty stock — backed by full reasoning.',
            style: AppText.body(size: 13, color: Colors.white70, height: 1.45),
          ),
          const SizedBox(height: 16),

          // Verdict chips
          const Row(
            children: [
              _VerdictChip(label: 'BUY', arrow: '▲', color: AppColors.buy),
              SizedBox(width: 8),
              _VerdictChip(label: 'HOLD', arrow: '—', color: AppColors.hold),
              SizedBox(width: 8),
              _VerdictChip(label: 'SELL', arrow: '▼', color: AppColors.sell),
            ],
          ),
          const SizedBox(height: 18),

          // CTA — browse reports (works for guests too)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/reports'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.text,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Explore reports',
                      style: AppText.body(size: 14, weight: FontWeight.w700, color: AppColors.text)),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward, size: 16, color: AppColors.text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerdictChip extends StatelessWidget {
  const _VerdictChip({required this.label, required this.arrow, required this.color});
  final String label;
  final String arrow;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$arrow $label',
          style: AppText.mono(size: 10, weight: FontWeight.w700, color: color)),
    );
  }
}

// ── Greeting ──────────────────────────────────────────────────────────────────

class _Greeting extends ConsumerWidget {
  const _Greeting();

  String get _timeOfDay {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final first = user?.firstName;
    final isGuest = user == null || user.isGuest;

    final heading = isGuest
        ? 'Welcome to AlgoVest.'
        : (first != null ? '$_timeOfDay, $first.' : '$_timeOfDay.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: AppText.fraunces(size: 22, weight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          'Which stock do you want to analyse today?',
          style: AppText.body(size: 14, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _AnalyseCard extends ConsumerWidget {
  void _openRequest(BuildContext context, WidgetRef ref, [String? prefill]) {
    final user = ref.read(currentUserProvider);
    if (user == null || user.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign in to request stock analysis.',
              style: AppText.body(size: 14, color: Colors.white)),
          backgroundColor: AppColors.text,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showRequestAnalysisSheet(context, prefill: prefill);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ANALYSE ANY NIFTY 500 STOCK',
                style: AppText.mono(size: 10, color: AppColors.dim),
              ),
              GestureDetector(
                onTap: () => _openRequest(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add, size: 12, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text('Request', style: AppText.body(size: 12, weight: FontWeight.w600, color: AppColors.accent)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularTickers
                .map((t) => _TickerChip(ticker: t, onTap: () => _openRequest(context, ref, t)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _TickerChip extends StatelessWidget {
  const _TickerChip({required this.ticker, required this.onTap});
  final String ticker;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.s2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(ticker, style: AppText.mono(size: 12, weight: FontWeight.w600, color: AppColors.muted)),
      ),
    );
  }
}

class _StatsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final subscriptionValue =
        user == null ? '—' : (user.isPremium ? 'Premium' : 'Free');
    final usageValue = user == null
        ? '—'
        : (user.isPremium ? 'Unlimited' : '${user.dailyUsage} / ${user.dailyLimit}');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _StatCell(label: 'SUBSCRIPTION', value: subscriptionValue)),
          Container(width: 1, height: 60, color: AppColors.border),
          Expanded(child: _StatCell(label: 'DAILY USAGE', value: usageValue)),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.mono(size: 9, color: AppColors.dim)),
          const SizedBox(height: 4),
          Text(value, style: AppText.fraunces(size: 18, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EmptyRecentlyViewed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          'No reports viewed today',
          style: AppText.body(size: 13, color: AppColors.muted),
        ),
      ),
    );
  }
}

// ── Your requests ─────────────────────────────────────────────────────────────

class _YourRequests extends ConsumerWidget {
  const _YourRequests();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null || user.isGuest) return const SizedBox.shrink();

    return ref.watch(requestsProvider).maybeWhen(
          data: (list) {
            if (list.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR REQUESTS', style: AppText.mono(size: 10, color: AppColors.dim)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < list.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 1, color: AppColors.border, indent: 14, endIndent: 14),
                        _RequestRow(request: list[i]),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request});
  final StockRequest request;

  (String, Color) get _statusStyle => switch (request.status) {
        'ready' => ('Ready', AppColors.buy),
        'failed' => ('Failed', AppColors.sell),
        'processing' => ('Processing', AppColors.hold),
        _ => ('Pending', AppColors.hold),
      };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusStyle;
    final ready = request.isReady;
    return InkWell(
      onTap: ready ? () => context.push('/reports/${request.ticker}') : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Text(request.symbol, style: AppText.mono(size: 13, weight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(label, style: AppText.mono(size: 10, weight: FontWeight.w700, color: color)),
            ),
            if (ready) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.dim),
            ],
          ],
        ),
      ),
    );
  }
}