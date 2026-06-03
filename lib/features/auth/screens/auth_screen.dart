import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/constants/api.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/user.dart';
import '../../../core/widgets/app_logo.dart';

enum _Step { contact, otp, success }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  _Step _step = _Step.contact;

  // Contact step
  final _contactController = TextEditingController();
  String? _contactError;
  bool _submitting = false;

  // OTP step
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());
  String? _otpError;
  int _resendCooldown = 0;
  Timer? _resendTimer;
  String _serverMessage = '';

  @override
  void dispose() {
    _contactController.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool get _isEmail => _contactController.text.contains('@');

  String _maskContact(String contact) {
    if (_isEmail) {
      final parts = contact.split('@');
      final user = parts[0];
      final masked = user.length > 2
          ? '${user[0]}***${user[user.length - 1]}'
          : '***';
      return '$masked@${parts[1]}';
    }
    if (contact.length > 5) {
      return '${contact.substring(0, 5)}*****${contact.substring(contact.length - 4)}';
    }
    return contact;
  }

  String? _validateContact(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Please enter your email or mobile number.';
    if (v.contains('@')) {
      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) {
        return 'Please enter a valid email address.';
      }
    } else {
      if (!RegExp(r'^\+?[0-9]{10,13}$').hasMatch(v)) {
        return 'Please enter a valid 10-digit mobile number (with +91).';
      }
    }
    return null;
  }

  void _startResendTimer() {
    setState(() => _resendCooldown = 30);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) t.cancel();
      });
    });
  }

  String get _otpString => _otpControllers.map((c) => c.text).join();

  void _clearOtp() {
    for (final c in _otpControllers) c.clear();
    _otpFocusNodes[0].requestFocus();
  }

  // ── API calls ──────────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    final contact = _contactController.text.trim();
    final err = _validateContact(contact);
    if (err != null) {
      setState(() => _contactError = err);
      return;
    }
    setState(() { _contactError = null; _submitting = true; });

    try {
      final res = await ApiService.instance.post<Map<String, dynamic>>(
        ApiConstants.sendOtp,
        data: {'contact': contact},
      );
      final data = res.data!;
      if (data['success'] == true) {
        setState(() {
          _serverMessage = data['message'] as String? ?? '';
          _step = _Step.otp;
        });
        _startResendTimer();
        Future.delayed(const Duration(milliseconds: 150), () {
          _otpFocusNodes[0].requestFocus();
        });
      } else {
        setState(() => _contactError = data['message'] as String? ?? 'Something went wrong.');
      }
    } catch (_) {
      setState(() => _contactError = 'Something went wrong. Please try again.');
    } finally {
      setState(() => _submitting = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpString;
    if (otp.length != 6) {
      setState(() => _otpError = 'Please enter all 6 digits.');
      return;
    }
    setState(() { _otpError = null; _submitting = true; });

    try {
      final res = await ApiService.instance.post<Map<String, dynamic>>(
        ApiConstants.verifyOtp,
        data: {'contact': _contactController.text.trim(), 'otp': otp},
      );
      final data = res.data!;
      if (data['success'] == true) {
        // Store tokens
        final access = data['access_token'] as String?;
        final refresh = data['refresh_token'] as String?;
        if (access != null && refresh != null) {
          await ApiService.instance.storeTokens(access, refresh);
        }
        setState(() => _step = _Step.success);
        // Set user in auth provider — router redirect handles navigation
        if (data['user'] != null) {
          ref.read(authProvider.notifier).setUser(
            User.fromJson(data['user'] as Map<String, dynamic>),
          );
        }
      } else {
        setState(() {
          _otpError = data['message'] as String? ?? 'Invalid OTP. Please try again.';
        });
        _clearOtp();
      }
    } catch (_) {
      setState(() => _otpError = 'Something went wrong. Please try again.');
    } finally {
      setState(() => _submitting = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0) return;
    setState(() { _submitting = true; _otpError = null; _serverMessage = ''; });
    _clearOtp();

    try {
      final res = await ApiService.instance.post<Map<String, dynamic>>(
        ApiConstants.sendOtp,
        data: {'contact': _contactController.text.trim()},
      );
      final data = res.data!;
      if (data['success'] == true) {
        setState(() => _serverMessage = data['message'] as String? ?? '');
        _startResendTimer();
      } else {
        setState(() => _otpError = data['message'] as String? ?? 'Failed to resend.');
      }
    } catch (_) {
      setState(() => _otpError = 'Failed to resend. Please try again.');
    } finally {
      setState(() => _submitting = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar with logo ──
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: AppLogo(height: 34),
            ),
            // ── Form area — scrollable, vertically centred ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 48),

                // Step content
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: switch (_step) {
                    _Step.contact => _ContactStep(
                        key: const ValueKey('contact'),
                        controller: _contactController,
                        error: _contactError,
                        submitting: _submitting,
                        isEmail: _isEmail,
                        onChanged: (_) => setState(() => _contactError = null),
                        onSubmit: _sendOtp,
                        onGuest: () {
                          ref.read(authProvider.notifier).continueAsGuest();
                          context.go('/dashboard');
                        },
                      ),
                    _Step.otp => _OtpStep(
                        key: const ValueKey('otp'),
                        masked: _maskContact(_contactController.text.trim()),
                        isEmail: _isEmail,
                        controllers: _otpControllers,
                        focusNodes: _otpFocusNodes,
                        error: _otpError,
                        serverMessage: _serverMessage,
                        submitting: _submitting,
                        resendCooldown: _resendCooldown,
                        onVerify: _verifyOtp,
                        onResend: _resendOtp,
                        onBack: () => setState(() {
                          _step = _Step.contact;
                          _clearOtp();
                          _otpError = null;
                          _serverMessage = '';
                          _resendTimer?.cancel();
                          _resendCooldown = 0;
                        }),
                        onOtpChanged: (index, value) {
                          setState(() => _otpError = null);
                          if (value.isNotEmpty && index < 5) {
                            _otpFocusNodes[index + 1].requestFocus();
                          }
                          // Auto-submit when all 6 filled
                          if (_otpString.length == 6) _verifyOtp();
                        },
                      ),
                    _Step.success => _SuccessStep(key: const ValueKey('success')),
                  },
                ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Contact step ──────────────────────────────────────────────────────────────

class _ContactStep extends StatelessWidget {
  const _ContactStep({
    super.key,
    required this.controller,
    required this.error,
    required this.submitting,
    required this.isEmail,
    required this.onChanged,
    required this.onSubmit,
    required this.onGuest,
  });

  final TextEditingController controller;
  final String? error;
  final bool submitting;
  final bool isEmail;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onGuest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Login or Sign up',
          style: AppText.fraunces(size: 22, weight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          "We'll send a one-time password to verify you.",
          style: AppText.body(size: 14, color: AppColors.muted),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          style: AppText.body(size: 16),
          decoration: InputDecoration(
            hintText: 'Mobile number or email',
            hintStyle: AppText.body(size: 16, color: AppColors.dim),
            errorText: error,
            suffixIcon: controller.text.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      isEmail ? '📧' : '💬',
                      style: const TextStyle(fontSize: 18),
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          controller.text.isNotEmpty
              ? (isEmail ? 'OTP will be sent to your email' : 'OTP will be sent via WhatsApp')
              : 'Enter your +91 mobile or email address',
          style: AppText.body(size: 12, color: AppColors.dim),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: submitting ? null : onSubmit,
            child: submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Send OTP'),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: AppText.body(size: 12, color: AppColors.dim)),
            ),
            const Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: submitting ? null : onGuest,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Continue as guest',
                style: AppText.body(size: 14, weight: FontWeight.w600, color: AppColors.text)),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Browse reports without an account. Sign in anytime to unlock premium.',
          style: AppText.body(size: 12, color: AppColors.dim),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── OTP step ──────────────────────────────────────────────────────────────────

class _OtpStep extends StatelessWidget {
  const _OtpStep({
    super.key,
    required this.masked,
    required this.isEmail,
    required this.controllers,
    required this.focusNodes,
    required this.error,
    required this.serverMessage,
    required this.submitting,
    required this.resendCooldown,
    required this.onVerify,
    required this.onResend,
    required this.onBack,
    required this.onOtpChanged,
  });

  final String masked;
  final bool isEmail;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final String? error;
  final String serverMessage;
  final bool submitting;
  final int resendCooldown;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final VoidCallback onBack;
  final void Function(int index, String value) onOtpChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify your identity',
          style: AppText.fraunces(size: 22, weight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter the code sent to $masked${isEmail ? '' : ' via WhatsApp'}',
          style: AppText.body(size: 14, color: AppColors.muted),
        ),
        const SizedBox(height: 28),

        // 6-box OTP input
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _OtpBox(
            controller: controllers[i],
            focusNode: focusNodes[i],
            hasError: error != null,
            onChanged: (value) {
              if (value.length > 1) {
                // Handle paste: distribute digits
                final digits = value.replaceAll(RegExp(r'\D'), '').split('');
                for (var j = 0; j < digits.length && i + j < 6; j++) {
                  controllers[i + j].text = digits[j];
                }
                if (i + digits.length - 1 < 6) {
                  focusNodes[(i + digits.length - 1).clamp(0, 5)].requestFocus();
                }
                onOtpChanged(i, value);
                return;
              }
              onOtpChanged(i, value);
            },
            onBackspace: () {
              if (controllers[i].text.isEmpty && i > 0) {
                controllers[i - 1].clear();
                focusNodes[i - 1].requestFocus();
              }
            },
          )),
        ),

        if (error != null) ...[
          const SizedBox(height: 10),
          Text(error!, style: AppText.body(size: 12, color: AppColors.sell), textAlign: TextAlign.center),
        ],
        if (serverMessage.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(serverMessage, style: AppText.body(size: 13, color: AppColors.accent), textAlign: TextAlign.center),
          ),
        ],

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: submitting ? null : onVerify,
            child: submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Verify'),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: resendCooldown > 0 || submitting ? null : onResend,
              child: Text(
                resendCooldown > 0 ? 'Resend in ${resendCooldown}s' : 'Resend OTP',
                style: AppText.body(size: 13, color: resendCooldown > 0 ? AppColors.dim : AppColors.muted),
              ),
            ),
            TextButton(
              onPressed: onBack,
              child: Text(
                '← Change ${isEmail ? 'email' : 'number'}',
                style: AppText.body(size: 13, color: AppColors.accent),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onBackspace,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (e) {
          if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.backspace) {
            onBackspace();
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 1,
          onChanged: onChanged,
          style: AppText.fraunces(size: 22, weight: FontWeight.w700),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: hasError ? AppColors.sell : AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: hasError ? AppColors.sell : AppColors.accent, width: 1.5),
            ),
            filled: true,
            fillColor: AppColors.s2,
          ),
        ),
      ),
    );
  }
}

// ── Success step ──────────────────────────────────────────────────────────────

class _SuccessStep extends StatelessWidget {
  const _SuccessStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.buy.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 32, color: AppColors.buy),
          ),
          const SizedBox(height: 16),
          Text('Welcome to AlgoVest!', style: AppText.fraunces(size: 20, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Redirecting you…', style: AppText.body(size: 14, color: AppColors.muted)),
        ],
      ),
    );
  }
}
