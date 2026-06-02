import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/requests_provider.dart';

/// Opens the "Request analysis" bottom sheet. [prefill] sets the initial ticker.
Future<void> showRequestAnalysisSheet(BuildContext context, {String? prefill}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _RequestSheet(prefill: prefill),
  );
}

class _RequestSheet extends ConsumerStatefulWidget {
  const _RequestSheet({this.prefill});
  final String? prefill;

  @override
  ConsumerState<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends ConsumerState<_RequestSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.prefill ?? '');
  bool _submitting = false;
  String? _error;
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Normalize "reliance" / "RELIANCE" -> "RELIANCE.NS"; leave existing suffix.
  String _normalize(String raw) {
    final t = raw.trim().toUpperCase();
    if (t.isEmpty) return t;
    return t.contains('.') ? t : '$t.NS';
  }

  Future<void> _submit() async {
    final ticker = _normalize(_controller.text);
    if (ticker.isEmpty) {
      setState(() => _error = 'Enter a stock symbol.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final err = await ref.read(requestsProvider.notifier).submit(ticker);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (err == null) {
        _done = true;
      } else {
        _error = err;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grabber
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (_done) ...[
            _SuccessContent(ticker: _normalize(_controller.text)),
          ] else ...[
            Text('Request analysis',
                style: AppText.fraunces(size: 20, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Our 12 AI agents will analyse any Nifty 500 stock for you.',
                style: AppText.body(size: 13, color: AppColors.muted)),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9.]')),
              ],
              style: AppText.mono(size: 16, weight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'e.g. RELIANCE',
                hintStyle: AppText.mono(size: 16, color: AppColors.dim),
                errorText: _error,
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.dim),
              ),
            ),
            const SizedBox(height: 6),
            Text('We add the .NS suffix automatically.',
                style: AppText.body(size: 12, color: AppColors.dim)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit request'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({required this.ticker});
  final String ticker;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.buy.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: AppColors.buy, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Request submitted',
                  style: AppText.fraunces(size: 19, weight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          "We're analysing ${ticker.replaceAll('.NS', '')}. It'll appear in your requests as “Ready” once the agents finish.",
          style: AppText.body(size: 14, color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}
