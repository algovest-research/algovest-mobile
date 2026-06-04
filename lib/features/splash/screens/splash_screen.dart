import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_logo.dart';

/// Launch screen — mirrors the algovest.online hero: a photo of an investor up
/// top, the AlgoVest lockup + tagline below. Auto-advances to Home after a beat
/// (tap anywhere to skip).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2400), _go);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _go() {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _go,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            // ── Hero photo ──
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/hero-investor.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  // Fade the photo into the background so the lockup below reads cleanly.
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 140,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, AppColors.bg],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Brand lockup ──
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppLogo(height: 40),
                    const SizedBox(height: 16),
                    Text(
                      'Clarity on every Indian stock.',
                      textAlign: TextAlign.center,
                      style: AppText.fraunces(size: 20, weight: FontWeight.w700, height: 1.15),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '12 AI agents debate the bull and bear case to deliver a clear verdict — backed by full reasoning.',
                      textAlign: TextAlign.center,
                      style: AppText.body(size: 13, color: AppColors.muted, height: 1.45),
                    ),
                    const SizedBox(height: 28),
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
