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
    _join();
  }

  Future<void> _join() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      try {
        await sl<ProjectsRepository>().joinProject(widget.projectId);
        if (mounted) {
          context.go('/project/${widget.projectId}');
        }
      } catch (e) {
        if (mounted) {
           // If already joined, just go there
           context.go('/project/${widget.projectId}');
        }
      }
    } else {
       context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
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
    );
  }
}
