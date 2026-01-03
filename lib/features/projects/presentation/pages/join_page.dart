import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskswebsite/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:taskswebsite/core/di/injection.dart';
import 'package:taskswebsite/features/projects/domain/repositories/projects_repository.dart';

class JoinPage extends StatefulWidget {
  final String projectId;

  const JoinPage({super.key, required this.projectId});

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  @override
  void initState() {
    super.initState();
    // Trigger auth check/join when widget mounts if already authenticated
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _join();
    }
  }

  Future<void> _join() async {
    try {
      await sl<ProjectsRepository>().joinProject(widget.projectId);
      if (mounted) {
        context.go('/project/${widget.projectId}');
      }
    } catch (e) {
      // If error (e.g. already member), just go to project
      debugPrint('Error joining project: $e');
      if (mounted) {
        context.go('/project/${widget.projectId}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _join();
        } else if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      child: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Joining project..."),
            ],
          ),
        ),
      ),
    );
  }
}
