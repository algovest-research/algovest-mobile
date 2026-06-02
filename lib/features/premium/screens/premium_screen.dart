import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/user.dart';

// NOTE: AlgoVest has no pricing/checkout endpoint yet. The price below is a
// placeholder for the UI — wire it to a real plans API before launch, and
// replace the CTA's "coming soon" handler with the real checkout flow.
const _placeholderPrice = '₹499';
const _placeholderPeriod = 'per month';

const _features = [
  (Icons.all_inclusive, 'Unlimited report views', 'No daily cap — open any report, any time.'),
  (Icons.groups_2_outlined, 'All 12 AI agents', 'Full conflict-free consensus on every stock.'),
  (Icons.filter_list, 'Full screener access', 'Filter the entire Nifty 500 by AI verdict.'),
  (Icons.bolt_outlined, 'Priority stock requests', 'Your analysis requests jump the queue.'),
  (Icons.notifications_active_outlined, 'Rating change alerts', 'Get notified when a verdict flips.'),
];

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Premium')),
      body: (user != null && user.isPremium)
          ? _PremiumActiveView(user: user)
          : const _UpgradeView(),
    );
  }
}

// ── Already-premium state ───────────────────────────────────────────────────

class _PremiumActiveView extends StatelessWidget {
  const _PremiumActiveView({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    final expiry = user.subscription.expiresAt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        _Hero(
          title: "You're Premium",
          subtitle: expiry != null
              ? 'Your plan renews on ${_formatDate(expiry)}.'
              : 'You have full, unlimited access.',
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('YOUR BENEFITS', style: AppText.mono(size: 10, color: AppColors.dim)),
        ),
        const _FeatureCard(enabledAll: true),
      ],
    );
  }
}

// ── Upgrade pitch ─────────────────────────────────────────────────────────────

class _UpgradeView extends StatelessWidget {
  const _UpgradeView();

  void _onUpgrade(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Checkout is coming soon.',
            style: AppText.body(size: 14, color: Colors.white)),
        backgroundColor: AppColors.text,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        const _Hero(
          title: 'AlgoVest Premium',
          subtitle: 'Unlimited AI-powered analysis on every Nifty 500 stock.',
        ),
        const SizedBox(height: 20),

        // ── Price ──
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accent.withOpacity(0.4)),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_placeholderPrice,
                  style: AppText.fraunces(size: 32, weight: FontWeight.w800, color: AppColors.text)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(_placeholderPeriod,
                    style: AppText.body(size: 13, color: AppColors.dim)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Cancel anytime',
                    style: AppText.mono(size: 10, weight: FontWeight.w700, color: AppColors.accent)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text("WHAT YOU'LL GET", style: AppText.mono(size: 10, color: AppColors.dim)),
        ),
        const _FeatureCard(enabledAll: false),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _onUpgrade(context),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Upgrade to Premium'),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text('Billed securely. Cancel anytime from Profile.',
              style: AppText.body(size: 11, color: AppColors.dim)),
        ),
      ],
    );
  }
}

// ── Shared pieces ─────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.text,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 14),
          Text(title, style: AppText.fraunces(size: 24, weight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 6),
          Text(subtitle, style: AppText.body(size: 14, color: Colors.white70, height: 1.4)),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.enabledAll});
  final bool enabledAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < _features.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            _FeatureRow(
              icon: _features[i].$1,
              title: _features[i].$2,
              subtitle: _features[i].$3,
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.buy.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.buy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.body(size: 14, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.body(size: 12, color: AppColors.dim, height: 1.35)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 8, top: 2),
            child: Icon(Icons.check_circle, size: 18, color: AppColors.buy),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';
