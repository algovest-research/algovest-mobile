import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/empty_state.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                'Watchlist',
                style: AppText.fraunces(size: 26, weight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Track the stocks you care about.',
                style: AppText.body(size: 14, color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              const Expanded(
                child: EmptyState(
                  icon: Icons.bookmark_border,
                  title: 'Your watchlist is empty',
                  message:
                      'Stocks you follow will appear here so you can keep an eye on their latest reports and verdicts.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
