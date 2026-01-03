import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/projects/presentation/pages/projects_page.dart';
import '../../features/projects/presentation/pages/join_page.dart';
import '../../features/projects/presentation/bloc/projects_bloc.dart';
import '../../features/tasks/presentation/pages/board_page.dart';
import '../../features/tasks/presentation/bloc/tasks_bloc.dart';
import '../../core/di/injection.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthWrapper(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/projects',
      builder: (context, state) => BlocProvider(
        create: (context) => sl<ProjectsBloc>(),
        child: const ProjectsPage(),
      ),
    ),
    GoRoute(
      path: '/project/:id',
      builder: (context, state) {
        final projectId = state.pathParameters['id']!;
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => sl<TasksBloc>()),
          ],
          child: BoardPage(projectId: projectId),
        );
      },
    ),
    GoRoute(
      path: '/join/:id',
      builder: (context, state) {
        final projectId = state.pathParameters['id']!;
        return JoinPage(projectId: projectId);
      },
    ),
  ],
);

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return BlocProvider(
            create: (context) => sl<ProjectsBloc>(),
            child: const ProjectsPage(),
          );
        } else if (state is AuthUnauthenticated || state is AuthInitial) {
          return const LoginPage();
        }
        
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
