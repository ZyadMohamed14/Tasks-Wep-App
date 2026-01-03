import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/tasks_repository.dart';
import '../models/task_model.dart';

class TasksRepositoryImpl implements TasksRepository {
  final SupabaseClient _supabase;

  TasksRepositoryImpl(this._supabase);

  // Helper method to check if user can modify tasks
  Future<bool> _canModifyTasks(String projectId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _supabase
        .from('project_members')
        .select('role')
        .eq('project_id', projectId)
        .eq('user_id', userId)
        .single();

    final role = response['role'] as String?;
    // Allow admins and members to modify tasks (adjust as needed)
    return role == 'admin' || role == 'member';
  }

  @override
  Future<List<TaskEntity>> getTasks(String projectId) async {
    final response = await _supabase
        .from('tasks')
        .select()
        .eq('project_id', projectId)
        .order('position', ascending: true);

    return (response as List).map((json) => TaskModel.fromJson(json)).toList();
  }

  @override
  Future<TaskEntity> createTask(String projectId, String title, String? description, String status) async {
    // Check permissions
    if (!await _canModifyTasks(projectId)) {
      throw Exception('You do not have permission to create tasks in this project');
    }

    // Get max position to append at the end
    final tasks = await getTasks(projectId);
    final maxPosition = tasks.isEmpty ? 0.0 : tasks.last.position;

    final response = await _supabase.from('tasks').insert({
      'project_id': projectId,
      'title': title,
      'description': description,
      'status': status,
      'position': maxPosition + 1000.0,
    }).select().single();

    return TaskModel.fromJson(response);
  }

  @override
  Future<void> updateTaskStatus(String taskId, String status) async {
    // Get task to find project_id
    final task = await _supabase
        .from('tasks')
        .select('project_id')
        .eq('id', taskId)
        .single();

    if (!await _canModifyTasks(task['project_id'])) {
      throw Exception('You do not have permission to update tasks in this project');
    }

    await _supabase.from('tasks').update({'status': status}).eq('id', taskId);
  }

  @override
  Future<void> updateTaskPosition(String taskId, double position) async {
    // Get task to find project_id
    final task = await _supabase
        .from('tasks')
        .select('project_id')
        .eq('id', taskId)
        .single();

    if (!await _canModifyTasks(task['project_id'])) {
      throw Exception('You do not have permission to update tasks in this project');
    }

    await _supabase.from('tasks').update({'position': position}).eq('id', taskId);
  }

  @override
  Future<void> assignTask(String taskId, String? userId) async {
    // Get task to find project_id
    final task = await _supabase
        .from('tasks')
        .select('project_id')
        .eq('id', taskId)
        .single();

    if (!await _canModifyTasks(task['project_id'])) {
      throw Exception('You do not have permission to assign tasks in this project');
    }

    await _supabase.from('tasks').update({'assigned_to': userId}).eq('id', taskId);
  }

  @override
  Future<void> updateTask(String taskId, String title, String? description) async {
    // Get task to find project_id
    final task = await _supabase
        .from('tasks')
        .select('project_id')
        .eq('id', taskId)
        .single();

    if (!await _canModifyTasks(task['project_id'])) {
      throw Exception('You do not have permission to edit this task');
    }

    await _supabase.from('tasks').update({
      'title': title,
      'description': description,
    }).eq('id', taskId);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    // Get task to find project_id
    final task = await _supabase
        .from('tasks')
        .select('project_id')
        .eq('id', taskId)
        .single();

    if (!await _canModifyTasks(task['project_id'])) {
      throw Exception('You do not have permission to delete this task');
    }

    await _supabase.from('tasks').delete().eq('id', taskId);
  }
}
