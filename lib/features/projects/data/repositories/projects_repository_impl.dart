import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/project_member_entity.dart';
import '../../domain/repositories/projects_repository.dart';
import '../models/project_model.dart';
import '../models/project_member_model.dart';

class ProjectsRepositoryImpl implements ProjectsRepository {
  final SupabaseClient _supabase;

  ProjectsRepositoryImpl(this._supabase);

  @override
  Future<List<ProjectEntity>> getProjects() async {
    final response = await _supabase
        .from('projects')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => ProjectModel.fromJson(json)).toList();
  }

  @override
  Future<ProjectEntity> createProject(String name, String? description) async {
    final userId = _supabase.auth.currentUser!.id;
    
    // Create the project
    final projectResponse = await _supabase.from('projects').insert({
      'name': name,
      'description': description,
      'creator_id': userId,
    }).select().single();

    final project = ProjectModel.fromJson(projectResponse);

    // Add the creator as an admin member
    await _supabase.from('project_members').insert({
      'project_id': project.id,
      'user_id': userId,
      'role': 'admin',
    });

    return project;
  }

  @override
  Future<void> joinProject(String projectId) async {
    final userId = _supabase.auth.currentUser!.id;
    
    await _supabase.from('project_members').insert({
      'project_id': projectId,
      'user_id': userId,
      'role': 'member',
    });
  }

  @override
  Future<List<ProjectMemberEntity>> getProjectMembers(String projectId) async {
    final response = await _supabase
        .from('project_members')
        .select('*, profiles:user_id(email, full_name, avatar_url)')
        .eq('project_id', projectId);
    
    return (response as List).map((json) => ProjectMemberModel.fromJson(json)).toList();
  }

  @override
  Future<String?> getCurrentUserRole(String projectId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('project_members')
        .select('role')
        .eq('project_id', projectId)
        .eq('user_id', userId)
        .maybeSingle();
    
    return response?['role'] as String?;
  }
}
