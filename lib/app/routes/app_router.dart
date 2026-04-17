import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/camera/presentation/camera_screen.dart';
import '../../features/reference/presentation/reference_screen.dart';
import '../../features/gallery/presentation/gallery_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../core/utils/app_logger.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter appRouter(Ref ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      
      final isLoggingIn = state.matchedLocation == '/login' ||
                         state.matchedLocation == '/register';
      
      if (!authState.isAuthenticated && !isLoggingIn) {
        AppLogger.logDebug('未登录，重定向到登录页', tag: 'Router');
        return '/login';
      }
      
      if (authState.isAuthenticated && isLoggingIn) {
        AppLogger.logDebug('已登录，重定向到主页', tag: 'Router');
        return '/camera';
      }
      
      return null;
    },
    refreshListenable: GoRouterRefreshNotifier(ref),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/camera',
                builder: (context, state) => const CameraScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reference',
                builder: (context, state) => const ReferenceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/gallery',
                builder: (context, state) => const GalleryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class GoRouterRefreshNotifier extends ChangeNotifier {
  final Ref _ref;
  
  GoRouterRefreshNotifier(this._ref) {
    _ref.listen(authProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated) {
        notifyListeners();
      }
    });
  }
}

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          border: const Border(
            top: BorderSide(color: Color(0xFF2A2A2A), width: 0.5),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.camera_alt_outlined,
                  activeIcon: Icons.camera_alt,
                  label: '相机',
                  isActive: navigationShell.currentIndex == 0,
                  onTap: () => _onTap(0),
                ),
                _NavItem(
                  icon: Icons.photo_library_outlined,
                  activeIcon: Icons.photo_library,
                  label: '参考',
                  isActive: navigationShell.currentIndex == 1,
                  onTap: () => _onTap(1),
                ),
                _NavItem(
                  icon: Icons.collections_outlined,
                  activeIcon: Icons.collections,
                  label: '相册',
                  isActive: navigationShell.currentIndex == 2,
                  onTap: () => _onTap(2),
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: '设置',
                  isActive: navigationShell.currentIndex == 3,
                  onTap: () => _onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive
                    ? const Color(0xFF1A73E8)
                    : const Color(0xFF707070),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFF1A73E8)
                      : const Color(0xFF707070),
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
