import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/repositories/projects_repository.dart';

// Events
abstract class ProjectsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadProjects extends ProjectsEvent {}
class CreateProject extends ProjectsEvent {
  final String name;
  final String? description;
  CreateProject(this.name, this.description);
  @override
  List<Object?> get props => [name, description];
}

// States
abstract class ProjectsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProjectsInitial extends ProjectsState {}
class ProjectsLoading extends ProjectsState {}
class ProjectsLoaded extends ProjectsState {
  final List<ProjectEntity> projects;
  ProjectsLoaded(this.projects);
  @override
  List<Object?> get props => [projects];
}
class ProjectsError extends ProjectsState {
  final String message;
  ProjectsError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class ProjectsBloc extends Bloc<ProjectsEvent, ProjectsState> {
  final ProjectsRepository _repository;

  ProjectsBloc(this._repository) : super(ProjectsInitial()) {
    on<LoadProjects>(_onLoadProjects);
    on<CreateProject>(_onCreateProject);
  }

  Future<void> _onLoadProjects(LoadProjects event, Emitter<ProjectsState> emit) async {
    emit(ProjectsLoading());
    try {
      final projects = await _repository.getProjects();
      emit(ProjectsLoaded(projects));
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  Future<void> _onCreateProject(CreateProject event, Emitter<ProjectsState> emit) async {
    try {
      await _repository.createProject(event.name, event.description);
      add(LoadProjects());
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }
}
