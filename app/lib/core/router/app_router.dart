import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/grades/presentation/grades_screen.dart';
import '../../features/grades/presentation/subject_detail_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/tasks/presentation/gantt_chart_screen.dart';
import '../../features/tasks/presentation/test_connection_screen.dart';
import '../theme/app_theme.dart';
import '../../shared/providers/navigation_providers.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: SelectableText(
        'Route not found: ${state.uri.path}\nException: ${state.error}',
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    ),
  ),
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/grades',
          name: 'grades',
          builder: (context, state) => const GradesScreen(),
          routes: [
            GoRoute(
              path: ':id',
              name: 'subject-detail',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return SubjectDetailScreen(subjectId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/tasks',
          name: 'tasks',
          builder: (context, state) => const TasksScreen(),
          routes: [
            GoRoute(
              path: 'gantt',
              name: 'gantt',
              builder: (context, state) => const GanttChartScreen(),
            ),
            GoRoute(
              path: 'test-connection',
              name: 'test-connection',
              builder: (context, state) => const TestConnectionScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMenuOpen = ref.watch(isMenuOpenProvider);
    final size = MediaQuery.of(context).size;
    final drawerWidth = (size.width * 0.75).clamp(240.0, 320.0);
    final location = GoRouterState.of(context).uri.path;

    int selectedIndex = 0;
    if (location.startsWith('/grades')) {
      selectedIndex = 1;
    } else if (location.startsWith('/tasks/test-connection')) {
      selectedIndex = 3;
    } else if (location.startsWith('/tasks')) {
      selectedIndex = 2;
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(
        children: [
          // ── Main Content Layer ──────────────────────────────────────────────
          child,

          // ── Edge Swipe Detector ─────────────────────────────────────────────
          if (!isMenuOpen)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 20, // 20px hit zone for swipe
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  if (details.delta.dx > 5) {
                    ref.read(isMenuOpenProvider.notifier).open();
                  }
                },
                behavior: HitTestBehavior.translucent,
              ),
            ),

          // ── Scrim Overlay Layer ─────────────────────────────────────────────
          if (isMenuOpen)
            GestureDetector(
              onTap: () => ref.read(isMenuOpenProvider.notifier).close(),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isMenuOpen ? 1.0 : 0.0,
                child: Container(color: Colors.black54),
              ),
            ),

          // ── Custom Drawer Layer ─────────────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutExpo,
            left: isMenuOpen ? 0 : -drawerWidth,
            top: 0,
            bottom: 0,
            width: drawerWidth,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                border: const Border(
                  right: BorderSide(
                    color: Color.fromARGB(255, 1, 1, 1),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(5, 0),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'KOSEN NAV',
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: AppTheme.neonGreen,
                                fontSize: 18,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppTheme.textSecondary,
                            ),
                            onPressed: () =>
                                ref.read(isMenuOpenProvider.notifier).close(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: AppTheme.border),
                    _DrawerItem(
                      icon: Icons.dashboard_rounded,
                      label: 'ホーム',
                      isSelected: selectedIndex == 0,
                      onTap: () {
                        context.go('/');
                        ref.read(isMenuOpenProvider.notifier).close();
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.school_rounded,
                      label: '履修科目',
                      isSelected: selectedIndex == 1,
                      onTap: () {
                        context.go('/grades');
                        ref.read(isMenuOpenProvider.notifier).close();
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.task_alt_rounded,
                      label: 'タスク',
                      isSelected: selectedIndex == 2,
                      onTap: () {
                        context.go('/tasks');
                        ref.read(isMenuOpenProvider.notifier).close();
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.network_check_rounded,
                      label: '接続テスト',
                      isSelected: selectedIndex == 3,
                      onTap: () {
                        context.go('/tasks/test-connection');
                        ref.read(isMenuOpenProvider.notifier).close();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.neonGreen : AppTheme.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          letterSpacing: 1.2,
        ),
      ),
      selected: isSelected,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    );
  }
}
