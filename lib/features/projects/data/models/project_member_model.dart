import '../../domain/entities/project_member_entity.dart';

class ProjectMemberModel extends ProjectMemberEntity {
  const ProjectMemberModel({
    required super.id,
    required super.projectId,
    required super.userId,
    required super.role,
    super.email,
    super.fullName,
    super.avatarUrl,
  });

  factory ProjectMemberModel.fromJson(Map<String, dynamic> json) {
    // Handle joined user data from Supabase
    final userData = json['profiles'] as Map<String, dynamic>?;
    
    return ProjectMemberModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      email: userData?['email'] as String?,
      fullName: userData?['full_name'] as String?,
      avatarUrl: userData?['avatar_url'] as String?,
    );
  }
}
