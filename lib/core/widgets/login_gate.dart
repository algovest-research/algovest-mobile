import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

/// A centred "sign in to continue" prompt for features that require an account.
/// Tapping the button takes the user to the auth screen; browsing as a guest is
/// otherwise unrestricted.
class LoginGate extends StatelessWidget {
  const LoginGate({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.fraunces(size: 18, weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.body(size: 14, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.push('/auth'),
              child: const Text('Sign in / Create account'),
            ),
          ],
        ),
      ),
    );
  }
}
