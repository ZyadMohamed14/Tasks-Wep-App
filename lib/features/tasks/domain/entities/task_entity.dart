import 'package:equatable/equatable.dart';

class TaskEntity extends Equatable {
  final String id;
  final String projectId;
  final String title;
  final String? description;
  final String status; // 'todo', 'in_progress', 'review', 'done'
  final String? assignedTo;
  final double position;
  final DateTime createdAt;

  const TaskEntity({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    required this.status,
    this.assignedTo,
    required this.position,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, projectId, title, description, status, assignedTo, position, createdAt];

  TaskEntity copyWith({
    String? status,
    double? position,
    String? assignedTo,
  }) {
    return TaskEntity(
      id: id,
      projectId: projectId,
      title: title,
      description: description,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      position: position ?? this.position,
      createdAt: createdAt,
    );
  }
}
