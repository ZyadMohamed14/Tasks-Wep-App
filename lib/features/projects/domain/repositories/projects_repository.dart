import '../entities/project_entity.dart';

abstract class ProjectsRepository {
  Future<List<ProjectEntity>> getProjects();
  Future<ProjectEntity> createProject(String name, String? description);
  Future<void> joinProject(String projectId);
}
