import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../constants/api.dart';

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  /// Default identity when no one is signed in. The app opens straight into the
  /// (appealing) Home as a guest rather than gating behind the login screen.
  static const _guest = User(
    id: 'guest',
    name: 'Guest',
    subscription: Subscription(status: 'none'),
    dailyUsage: 0,
    dailyLimit: 5,
  );

  Future<void> _load() async {
    try {
      final res = await ApiService.instance.get<Map<String, dynamic>>(ApiConstants.me);
      final data = res.data!;
      final user = data['user'] != null ? User.fromJson(data['user'] as Map<String, dynamic>) : null;
      // Fall back to a guest so launch never lands on the login screen.
      state = AsyncValue.data(user ?? _guest);
    } catch (_) {
      state = const AsyncValue.data(_guest);
    }
  }

  void setUser(User user) {
    state = AsyncValue.data(user);
  }

  /// Enter the app as a guest — no account, free tier.
  void continueAsGuest() {
    state = const AsyncValue.data(_guest);
  }

  Future<void> logout() async {
    try {
      await ApiService.instance.post<void>(ApiConstants.logout);
    } catch (_) {}
    await ApiService.instance.clearTokens();
    // Drop back to a guest session (Home), not the login screen.
    state = const AsyncValue.data(_guest);
  }

  Future<void> refresh() => _load();
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier();
});

// Convenience: resolved User? (null while loading too)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).valueOrNull;
});