import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../constants/api.dart';

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.instance.get<Map<String, dynamic>>(ApiConstants.me);
      final data = res.data!;
      final user = data['user'] != null ? User.fromJson(data['user'] as Map<String, dynamic>) : null;
      state = AsyncValue.data(user);
    } catch (_) {
      state = const AsyncValue.data(null);
    }
  }

  void setUser(User user) {
    state = AsyncValue.data(user);
  }

  /// Enter the app as a guest — no account, free tier. Session-only: there is no
  /// token, so a relaunch (which re-checks /auth/me) returns to the auth screen.
  void continueAsGuest() {
    state = const AsyncValue.data(User(
      id: 'guest',
      name: 'Guest',
      subscription: Subscription(status: 'none'),
      dailyUsage: 0,
      dailyLimit: 5,
    ));
  }

  Future<void> logout() async {
    try {
      await ApiService.instance.post<void>(ApiConstants.logout);
    } catch (_) {}
    await ApiService.instance.clearTokens();
    state = const AsyncValue.data(null);
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