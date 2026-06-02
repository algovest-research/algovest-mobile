import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The AlgoVest logo lockup — the rising bar-chart mark + the "AlgoVest"
/// wordmark ("Algo" in navy, "Vest" in accent), matching the website header.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.height = 28});

  final double height;

  @override
  Widget build(BuildContext context) {
    final fontSize = height * 0.86;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/algovest_mark.png',
          height: height * 0.92,
          filterQuality: FilterQuality.medium,
          semanticLabel: 'AlgoVest',
        ),
        SizedBox(width: height * 0.24),
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: 'Algo',
              style: AppText.body(size: fontSize, weight: FontWeight.w800, color: AppColors.text),
            ),
            TextSpan(
              text: 'Vest',
              style: AppText.body(size: fontSize, weight: FontWeight.w800, color: AppColors.accent),
            ),
          ]),
        ),
      ],
    );
  }
}
