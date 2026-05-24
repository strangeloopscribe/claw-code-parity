import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/profile_setup_screen.dart';
import '../screens/auth/family_setup_screen.dart';
import '../screens/shell_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/calendar/event_form_screen.dart';
import '../screens/lists/lists_screen.dart';
import '../screens/lists/list_detail_screen.dart';
import '../screens/journal/journal_screen.dart';
import '../screens/journal/journal_entry_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final loc = state.matchedLocation;
      final isAuthRoute = loc.startsWith('/auth/');
      final isSplash = loc == '/';

      if (user == null && !isAuthRoute && !isSplash) return '/auth/login';
      if (user != null && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/auth/family-setup',
        builder: (context, state) => const FamilySetupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ShellScreen(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/calendar',
              builder: (context, state) => const CalendarScreen(),
              routes: [
                GoRoute(
                  path: 'event/new',
                  builder: (context, state) {
                    final dateStr = state.uri.queryParameters['date'];
                    return EventFormScreen(
                      initialDate:
                          dateStr != null ? DateTime.parse(dateStr) : null,
                    );
                  },
                ),
                GoRoute(
                  path: 'event/:id',
                  builder: (context, state) => EventFormScreen(
                    eventId: state.pathParameters['id'],
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/lists',
              builder: (context, state) => const ListsScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => ListDetailScreen(
                    listId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/journal',
              builder: (context, state) => const JournalScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (context, state) => const JournalEntryScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => JournalEntryScreen(
                    entryId: state.pathParameters['id'],
                  ),
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});
