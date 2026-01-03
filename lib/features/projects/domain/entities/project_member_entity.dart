import 'package:equatable/equatable.dart';

class ProjectMemberEntity extends Equatable {
  final String id;
  final String projectId;
  final String userId;
  final String role; // 'admin' or 'member'
  final String? email;
  final String? fullName;
  final String? avatarUrl;

  const ProjectMemberEntity({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.role,
    this.email,
    this.fullName,
    this.avatarUrl,
  });

  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props => [id, projectId, userId, role, email, fullName, avatarUrl];
}
