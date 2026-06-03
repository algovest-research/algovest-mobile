import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/login_gate.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isGuest = user == null || user.isGuest;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLogo(height: 26),
              const SizedBox(height: 20),
              Text(
                'Portfolio',
                style: AppText.fraunces(size: 26, weight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'See how your holdings are performing.',
                style: AppText.body(size: 14, color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: isGuest
                    ? const LoginGate(
                        icon: Icons.lock_outline,
                        title: 'Sign in to view your portfolio',
                        message:
                            'Your holdings are tied to your account. Sign in or create a free account to track their value and verdicts.',
                      )
                    : const EmptyState(
                        icon: Icons.pie_chart_outline,
                        title: 'No holdings yet',
                        message:
                            'Add the stocks you own to track their value, allocation and AlgoVest verdicts in one place.',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
