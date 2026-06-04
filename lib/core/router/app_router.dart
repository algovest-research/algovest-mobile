import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/reports/screens/reports_list_screen.dart';
import '../../features/reports/screens/report_detail_screen.dart';
import '../../features/screener/screens/screener_screen.dart';
import '../../features/premium/screens/premium_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/watchlist/screens/watchlist_screen.dart';
import '../../features/portfolio/screens/portfolio_screen.dart';

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
    final isAuthed = user != null && !user.isGuest;

    // Signed-in users shouldn't sit on the login screen.
    if (isAuthed && isOnAuth) return '/dashboard';
    // Everyone else (including guests) browses freely — login is never forced.
    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    refreshListenable: notifier,
    redirect: notifier.redirect,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
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
            path: '/watchlist',
            builder: (_, __) => const WatchlistScreen(),
          ),
          GoRoute(
            path: '/portfolio',
            builder: (_, __) => const PortfolioScreen(),
          ),
          // Kept reachable (e.g. from Home) but no longer a bottom-nav tab.
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
      String s when s.startsWith('/watchlist') => 1,
      String s when s.startsWith('/reports')   => 2,
      String s when s.startsWith('/portfolio') => 3,
      String s when s.startsWith('/premium')   => 4, // upgrade screen, shown under Profile
      String s when s.startsWith('/profile')   => 4,
      _                                         => 0,
    };

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) {
          const routes = ['/dashboard', '/watchlist', '/reports', '/portfolio', '/profile'];
          context.go(routes[i]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),         selectedIcon: Icon(Icons.home),               label: 'Home'),
          NavigationDestination(icon: Icon(Icons.bookmark_border),       selectedIcon: Icon(Icons.bookmark),           label: 'Watchlist'),
          NavigationDestination(icon: Icon(Icons.article_outlined),      selectedIcon: Icon(Icons.article),            label: 'Report'),
          NavigationDestination(icon: Icon(Icons.pie_chart_outline),     selectedIcon: Icon(Icons.pie_chart),          label: 'Portfolio'),
          NavigationDestination(icon: Icon(Icons.person_outline),        selectedIcon: Icon(Icons.person),             label: 'Profile'),
        ],
      ),
    );
  }
}