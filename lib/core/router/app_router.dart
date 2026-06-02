import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/reports/screens/reports_list_screen.dart';
import '../../features/reports/screens/report_detail_screen.dart';
import '../../features/screener/screens/screener_screen.dart';
import '../../features/premium/screens/premium_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<User?>>(authProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);

    // While loading, stay put
    if (authState.isLoading) return null;

    final user = authState.valueOrNull;
    final isOnAuth = state.matchedLocation.startsWith('/auth');

    if (user == null && !isOnAuth) return '/auth';
    if (user != null && isOnAuth) return '/dashboard';
    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    refreshListenable: notifier,
    redirect: notifier.redirect,
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/auth',
        builder: (_, __) => const AuthScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNav(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (_, __) => const ReportsListScreen(),
            routes: [
              GoRoute(
                path: ':ticker',
                builder: (_, state) => ReportDetailScreen(
                  ticker: state.pathParameters['ticker']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/screener',
            builder: (_, __) => const ScreenerScreen(),
          ),
          GoRoute(
            path: '/premium',
            builder: (_, __) => const PremiumScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

class ScaffoldWithNav extends ConsumerWidget {
  const ScaffoldWithNav({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = switch (location) {
      String s when s.startsWith('/dashboard') => 0,
      String s when s.startsWith('/reports')   => 1,
      String s when s.startsWith('/screener')  => 2,
      String s when s.startsWith('/premium')   => 3, // upgrade screen, shown under Profile
      String s when s.startsWith('/profile')   => 3,
      _                                         => 0,
    };

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) {
          const routes = ['/dashboard', '/reports', '/screener', '/profile'];
          context.go(routes[i]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),   selectedIcon: Icon(Icons.home),        label: 'Home'),
          NavigationDestination(icon: Icon(Icons.article_outlined), selectedIcon: Icon(Icons.article),     label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.filter_list),      selectedIcon: Icon(Icons.filter_list), label: 'Screener'),
          NavigationDestination(icon: Icon(Icons.person_outline),   selectedIcon: Icon(Icons.person),      label: 'Profile'),
        ],
      ),
    );
  }
}