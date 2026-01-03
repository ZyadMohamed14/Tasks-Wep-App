import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/tasks_repository.dart';
import '../models/task_model.dart';

class TasksRepositoryImpl implements TasksRepository {
  final SupabaseClient _supabase;

  TasksRepositoryImpl(this._supabase);

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
    // Get max position to append at the end
    final tasks = await getTasks(projectId);
    final maxPosition = tasks.isEmpty ? 0.0 : tasks.last.position;

    final response = await _supabase.from('tasks').insert({
      'project_id': projectId,
      'title': title,
      'description': description,
      'status': status,
      'position': maxPosition + 1000.0, // Large increments avoid frequent re-positioning
    }).select().single();

    return TaskModel.fromJson(response);
  }

  @override
  Future<void> updateTaskStatus(String taskId, String status) async {
    await _supabase.from('tasks').update({'status': status}).eq('id', taskId);
  }

  @override
  Future<void> updateTaskPosition(String taskId, double position) async {
    await _supabase.from('tasks').update({'position': position}).eq('id', taskId);
  }

  @override
  Future<void> assignTask(String taskId, String? userId) async {
    await _supabase.from('tasks').update({'assigned_to': userId}).eq('id', taskId);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _supabase.from('tasks').delete().eq('id', taskId);
  }
}
