import '../entities/task_entity.dart';

abstract class TasksRepository {
  Future<List<TaskEntity>> getTasks(String projectId);
  Future<TaskEntity> createTask(String projectId, String title, String? description, String status);
  Future<void> updateTaskStatus(String taskId, String status);
  Future<void> updateTaskPosition(String taskId, double position);
  Future<void> assignTask(String taskId, String? userId);
  Future<void> deleteTask(String taskId);
}
