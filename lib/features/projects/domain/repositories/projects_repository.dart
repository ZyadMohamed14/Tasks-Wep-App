import '../entities/project_entity.dart';
import '../entities/project_member_entity.dart';

abstract class ProjectsRepository {
  Future<List<ProjectEntity>> getProjects();
  Future<ProjectEntity> createProject(String name, String? description);
  Future<void> joinProject(String projectId);
  Future<List<ProjectMemberEntity>> getProjectMembers(String projectId);
  Future<String?> getCurrentUserRole(String projectId);
}
