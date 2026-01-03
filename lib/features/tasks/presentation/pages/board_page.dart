import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../bloc/tasks_bloc.dart';
import '../../domain/entities/task_entity.dart';
import '../../../projects/domain/entities/project_member_entity.dart';

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
      body: BlocConsumer<TasksBloc, TasksState>(
        listener: (context, state) {
          if (state is TasksError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
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
                      members: state.members,
                      isAdmin: state.isCurrentUserAdmin,
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
  final List<ProjectMemberEntity> members;
  final bool isAdmin;

  const KanbanColumn({
    super.key,
    required this.status,
    required this.tasks,
    required this.projectId,
    required this.members,
    required this.isAdmin,
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
        final isHovering = candidateData.isNotEmpty;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isHovering 
                ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                : Theme.of(context).cardColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: isHovering 
                ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getStatusTitle(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${tasks.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
                    return KanbanCard(
                      task: task,
                      members: members,
                      isAdmin: isAdmin,
                      projectId: projectId,
                    );
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
    final tasksBloc = context.read<TasksBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                tasksBloc.add(
                  AddTask(projectId, titleController.text, descController.text, status),
                );
                Navigator.pop(dialogContext);
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
  final List<ProjectMemberEntity> members;
  final bool isAdmin;
  final String projectId;

  const KanbanCard({
    super.key,
    required this.task,
    required this.members,
    required this.isAdmin,
    required this.projectId,
  });

  ProjectMemberEntity? _getAssignedMember() {
    if (task.assignedTo == null) return null;
    try {
      return members.firstWhere((m) => m.userId == task.assignedTo);
    } catch (_) {
      return null;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<TasksBloc>().add(DeleteTask(task.id, projectId));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context) {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description);
    final tasksBloc = context.read<TasksBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Task'),
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                tasksBloc.add(
                  EditTask(task.id, projectId, titleController.text, descController.text),
                );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context) {
    final tasksBloc = context.read<TasksBloc>();
    
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assign Task',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Unassign option
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person_off, color: Colors.white),
                ),
                title: const Text('Unassign'),
                onTap: () {
                  tasksBloc.add(AssignTask(task.id, projectId, null));
                  Navigator.pop(bottomSheetContext);
                },
              ),
              const Divider(),
              // Member list
              ...members.map((member) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: member.avatarUrl != null 
                      ? NetworkImage(member.avatarUrl!) 
                      : null,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: member.avatarUrl == null 
                      ? Text(
                          (member.fullName ?? member.email ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
                title: Text(member.fullName ?? member.email ?? 'Unknown'),
                subtitle: Text(member.role),
                trailing: task.assignedTo == member.userId 
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  tasksBloc.add(AssignTask(task.id, projectId, member.userId));
                  Navigator.pop(bottomSheetContext);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignedMember = _getAssignedMember();
    
    return Draggable<TaskEntity>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 280,
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildCard(context, assignedMember),
      ),
      child: _buildCard(context, assignedMember),
    );
  }

  Widget _buildCard(
      BuildContext context,
      ProjectMemberEntity? assignedMember,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),

            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.white70),
                  onPressed: () => _showEditTaskDialog(context),
                  tooltip: 'Edit Task',
                ),
                const SizedBox(width: 8),

                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                  onPressed: () => _showDeleteConfirmation(context),
                  tooltip: 'Delete Task',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),

                const SizedBox(width: 12),

                GestureDetector(
                  onTap: () => _showAssignDialog(context),
                  child: assignedMember != null
                      ? CircleAvatar(
                    radius: 14,
                    backgroundImage: assignedMember.avatarUrl != null
                        ? NetworkImage(assignedMember.avatarUrl!)
                        : null,
                    backgroundColor:
                    Theme.of(context).primaryColor,
                    child: assignedMember.avatarUrl == null
                        ? Text(
                      (assignedMember.fullName ??
                          assignedMember.email ??
                          'U')[0]
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    )
                        : null,
                  )
                      : Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_add,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
