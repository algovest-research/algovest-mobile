import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/user.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Profile')),
      body: authState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
        ),
        error: (_, __) => Center(
          child: Text('Could not load your profile.',
              style: AppText.body(size: 14, color: AppColors.muted)),
        ),
        data: (user) => user == null
            ? Center(
                child: Text('You are not signed in.',
                    style: AppText.body(size: 14, color: AppColors.muted)),
              )
            : _ProfileBody(user: user),
      ),
    );
  }
}

// ── Body ────────────────────────────────────────────────────────────────────

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.user});
  final User user;

  String get _initials {
    final name = user.name?.trim();
    if (name != null && name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }
    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return 'AV';
  }

  String get _displayName => user.name?.trim().isNotEmpty == true
      ? user.name!.trim()
      : 'AlgoVest Investor';

  String? get _contact => user.email ?? user.phone;

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('Log out?', style: AppText.fraunces(size: 18, weight: FontWeight.w700)),
        content: Text('You will need to verify your number or email again to sign back in.',
            style: AppText.body(size: 14, color: AppColors.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: AppText.body(size: 14, color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Log out', style: AppText.body(size: 14, weight: FontWeight.w700, color: AppColors.sell)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      // Router redirect (refreshListenable on authProvider) handles navigation to /auth.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (user.isGuest) return const _GuestProfileBody();

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => ref.read(authProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // ── Identity header ──
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(_initials,
                    style: AppText.fraunces(size: 20, weight: FontWeight.w800, color: AppColors.accent)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_displayName,
                        style: AppText.fraunces(size: 20, weight: FontWeight.w700),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (_contact != null) ...[
                      const SizedBox(height: 2),
                      Text(_contact!,
                          style: AppText.body(size: 13, color: AppColors.dim),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Subscription ──
          _SubscriptionCard(user: user),
          const SizedBox(height: 12),

          // ── Usage ──
          _UsageCard(user: user),
          const SizedBox(height: 24),

          // ── Account details ──
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('ACCOUNT', style: AppText.mono(size: 10, color: AppColors.dim)),
          ),
          _InfoCard(rows: [
            if (user.email != null) _InfoRow(icon: Icons.mail_outline, label: 'Email', value: user.email!),
            if (user.phone != null) _InfoRow(icon: Icons.phone_outlined, label: 'Mobile', value: user.phone!),
            _InfoRow(icon: Icons.badge_outlined, label: 'Account ID', value: user.id),
          ]),
          const SizedBox(height: 24),

          // ── Logout ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context, ref),
              icon: const Icon(Icons.logout, size: 18, color: AppColors.sell),
              label: Text('Log out',
                  style: AppText.body(size: 14, weight: FontWeight.w600, color: AppColors.sell)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Center(
            child: Text('AlgoVest · v1.0.0',
                style: AppText.mono(size: 10, color: AppColors.dim)),
          ),
        ],
      ),
    );
  }
}

// ── Guest profile ─────────────────────────────────────────────────────────────

class _GuestProfileBody extends StatelessWidget {
  const _GuestProfileBody();

  static const _perks = [
    (Icons.insights_outlined, 'Request analysis for any Nifty 500 stock'),
    (Icons.bookmark_added_outlined, 'Save stocks to your watchlist'),
    (Icons.pie_chart_outline, 'Track your portfolio and its verdicts'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // ── Identity header ──
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.person_outline, color: AppColors.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Browsing as guest',
                      style: AppText.fraunces(size: 20, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Not signed in',
                      style: AppText.body(size: 13, color: AppColors.dim)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Sign-in CTA ──
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Unlock the full experience',
                  style: AppText.fraunces(size: 18, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'Create a free account to do more with AlgoVest.',
                style: AppText.body(size: 13, color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 16),
              for (final (icon, label) in _perks) ...[
                Row(
                  children: [
                    Icon(icon, size: 18, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(label,
                          style: AppText.body(size: 14, color: AppColors.text)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 2),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/auth'),
                  child: const Text('Sign in / Create account'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Center(
          child: Text('AlgoVest · v1.0.0',
              style: AppText.mono(size: 10, color: AppColors.dim)),
        ),
      ],
    );
  }
}

// ── Subscription card ─────────────────────────────────────────────────────────

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    final isPremium = user.isPremium;
    final expiry = user.subscription.expiresAt;

    return Container(
      decoration: BoxDecoration(
        color: isPremium ? AppColors.text : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isPremium ? AppColors.text : AppColors.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isPremium ? Icons.workspace_premium : Icons.lock_open,
                  size: 18, color: isPremium ? Colors.white : AppColors.dim),
              const SizedBox(width: 8),
              Text(
                isPremium ? 'Premium' : 'Free plan',
                style: AppText.fraunces(
                    size: 18,
                    weight: FontWeight.w700,
                    color: isPremium ? Colors.white : AppColors.text),
              ),
              const Spacer(),
              _StatusBadge(status: user.subscription.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isPremium
                ? (expiry != null
                    ? 'Renews on ${_formatDate(expiry)}'
                    : 'Unlimited access to every report.')
                : 'Upgrade for unlimited report views and screeners.',
            style: AppText.body(
                size: 13,
                color: isPremium ? Colors.white70 : AppColors.muted,
                height: 1.4),
          ),
          if (!isPremium) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/premium'),
                child: const Text('Upgrade to Premium'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active'  => ('ACTIVE', AppColors.buy),
      'expired' => ('EXPIRED', AppColors.sell),
      _         => ('FREE', AppColors.dim),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(status == 'active' ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: AppText.mono(size: 9, weight: FontWeight.w700, color: status == 'active' ? const Color(0xFF4ADE80) : color)),
    );
  }
}

// ── Usage card ──────────────────────────────────────────────────────────────

class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    final isPremium = user.isPremium;
    final used = user.dailyUsage;
    final limit = user.dailyLimit;
    final fraction = (limit > 0) ? (used / limit).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('TODAY', style: AppText.mono(size: 10, color: AppColors.dim)),
              const Spacer(),
              Text(
                isPremium ? 'Unlimited' : '$used / $limit',
                style: AppText.fraunces(size: 16, weight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isPremium ? 'Report views remaining' : 'Free report views used today',
            style: AppText.body(size: 13, color: AppColors.muted),
          ),
          if (!isPremium) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor: AppColors.s2,
                valueColor: AlwaysStoppedAnimation(
                  fraction >= 1.0 ? AppColors.sell : AppColors.accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Account info ──────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i < rows.length - 1) {
        children.add(const Divider(height: 1, color: AppColors.border, indent: 48));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.dim),
          const SizedBox(width: 14),
          Text(label, style: AppText.body(size: 14, color: AppColors.muted)),
          const Spacer(),
          Flexible(
            child: Text(value,
                style: AppText.body(size: 14, weight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
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
