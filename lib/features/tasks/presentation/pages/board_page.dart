import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../bloc/tasks_bloc.dart';
import '../../domain/entities/task_entity.dart';

class BoardPage extends StatefulWidget {
  final String projectId;

  const BoardPage({super.key, required this.projectId});

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  final List<String> statuses = ['todo', 'in_progress', 'review', 'done'];

  @override
  void initState() {
    super.initState();
    context.read<TasksBloc>().add(LoadTasks(widget.projectId));
  }

  void _shareProjectLink() {
    final baseUrl = Uri.base.origin;
    final joinLink = '$baseUrl/#/join/${widget.projectId}';
    
    Clipboard.setData(ClipboardData(text: joinLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Join link copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareProjectLink,
          ),
        ],
      ),
      body: BlocBuilder<TasksBloc, TasksState>(
        builder: (context, state) {
          if (state is TasksLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TasksLoaded) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: statuses.map((status) {
                  final tasksInStatus = state.tasks.where((t) => t.status == status).toList();
                  return Expanded(
                    child: KanbanColumn(
                      status: status,
                      tasks: tasksInStatus,
                      projectId: widget.projectId,
                    ),
                  );
                }).toList(),
              ),
            );
          } else if (state is TasksError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class KanbanColumn extends StatelessWidget {
  final String status;
  final List<TaskEntity> tasks;
  final String projectId;

  const KanbanColumn({
    super.key,
    required this.status,
    required this.tasks,
    required this.projectId,
  });

  String _getStatusTitle() {
    switch (status) {
      case 'todo': return 'To Do';
      case 'in_progress': return 'In Progress';
      case 'review': return 'Review';
      case 'done': return 'Done';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<TaskEntity>(
      onAcceptWithDetails: (details) {
        final task = details.data;
        if (task.status != status) {
          // Calculate new position (simplified: end of list)
          final newPos = tasks.isEmpty ? 1000.0 : tasks.last.position + 1000.0;
          context.read<TasksBloc>().add(MoveTask(task, status, newPos));
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getStatusTitle(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () => _showAddTaskDialog(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return KanbanCard(task: task);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Task Title'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                context.read<TasksBloc>().add(
                  AddTask(projectId, titleController.text, descController.text, status),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class KanbanCard extends StatelessWidget {
  final TaskEntity task;

  const KanbanCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<TaskEntity>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 280,
          child: Card(
            elevation: 8,
            child: ListTile(
              title: Text(task.title),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(title: Text(task.title)),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(task.title),
          subtitle: task.description != null ? Text(task.description!, maxLines: 2, overflow: TextOverflow.ellipsis) : null,
          trailing: task.assignedTo != null ? const Icon(Icons.person, size: 16) : null,
          onTap: () {
             // Task detail logic
          },
        ),
      ),
    );
  }
}
