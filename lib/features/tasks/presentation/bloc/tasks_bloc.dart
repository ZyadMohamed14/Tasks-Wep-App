import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/tasks_repository.dart';
import '../../../projects/domain/entities/project_member_entity.dart';
import '../../../projects/domain/repositories/projects_repository.dart';

// Events
abstract class TasksEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTasks extends TasksEvent {
  final String projectId;
  LoadTasks(this.projectId);
  @override
  List<Object?> get props => [projectId];
}

class AddTask extends TasksEvent {
  final String projectId;
  final String title;
  final String? description;
  final String status;
  AddTask(this.projectId, this.title, this.description, this.status);
  @override
  List<Object?> get props => [projectId, title, description, status];
}

class MoveTask extends TasksEvent {
  final TaskEntity task;
  final String newStatus;
  final double newPosition;
  MoveTask(this.task, this.newStatus, this.newPosition);
  @override
  List<Object?> get props => [task, newStatus, newPosition];
}

class AssignTask extends TasksEvent {
  final String taskId;
  final String projectId;
  final String? userId;
  AssignTask(this.taskId, this.projectId, this.userId);
  @override
  List<Object?> get props => [taskId, projectId, userId];

}

class EditTask extends TasksEvent {
  final String taskId;
  final String projectId;
  final String title;
  final String? description;
  EditTask(this.taskId, this.projectId, this.title, this.description);
  @override
  List<Object?> get props => [taskId, projectId, title, description];
}

class DeleteTask extends TasksEvent {
  final String taskId;
  final String projectId;
  DeleteTask(this.taskId, this.projectId);
  @override
  List<Object?> get props => [taskId, projectId];
}

// States
abstract class TasksState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TasksInitial extends TasksState {}
class TasksLoading extends TasksState {}
class TasksLoaded extends TasksState {
  final List<TaskEntity> tasks;
  final List<ProjectMemberEntity> members;
  final String? currentUserRole;
  final String projectId;

  TasksLoaded({
    required this.tasks,
    required this.members,
    required this.currentUserRole,
    required this.projectId,
  });

  bool get isCurrentUserAdmin => currentUserRole == 'admin';

  @override
  List<Object?> get props => [tasks, members, currentUserRole, projectId];
}
class TasksError extends TasksState {
  final String message;
  TasksError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class TasksBloc extends Bloc<TasksEvent, TasksState> {
  final TasksRepository _tasksRepository;
  final ProjectsRepository _projectsRepository;

  TasksBloc(this._tasksRepository, this._projectsRepository) : super(TasksInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<AddTask>(_onAddTask);
    on<MoveTask>(_onMoveTask);

    on<AssignTask>(_onAssignTask);
    on<EditTask>(_onEditTask);
    on<DeleteTask>(_onDeleteTask);
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TasksState> emit) async {
    emit(TasksLoading());
    try {
      final results = await Future.wait([
        _tasksRepository.getTasks(event.projectId),
        _projectsRepository.getProjectMembers(event.projectId),
        _projectsRepository.getCurrentUserRole(event.projectId),
      ]);
      
      emit(TasksLoaded(
        tasks: results[0] as List<TaskEntity>,
        members: results[1] as List<ProjectMemberEntity>,
        currentUserRole: results[2] as String?,
        projectId: event.projectId,
      ));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TasksState> emit) async {
    try {
      await _tasksRepository.createTask(event.projectId, event.title, event.description, event.status);
      add(LoadTasks(event.projectId));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onMoveTask(MoveTask event, Emitter<TasksState> emit) async {
    // Optimistic update
    if (state is TasksLoaded) {
      final currentState = state as TasksLoaded;
      final updatedTasks = currentState.tasks.map((t) {
        if (t.id == event.task.id) {
          return t.copyWith(status: event.newStatus, position: event.newPosition);
        }
        return t;
      }).toList();
      emit(TasksLoaded(
        tasks: updatedTasks,
        members: currentState.members,
        currentUserRole: currentState.currentUserRole,
        projectId: currentState.projectId,
      ));
    }

    try {
      await _tasksRepository.updateTaskStatus(event.task.id, event.newStatus);
      await _tasksRepository.updateTaskPosition(event.task.id, event.newPosition);
    } catch (e) {
      // Revert on error
      add(LoadTasks(event.task.projectId));
    }
  }

  Future<void> _onAssignTask(AssignTask event, Emitter<TasksState> emit) async {
    try {
      await _tasksRepository.assignTask(event.taskId, event.userId);
      add(LoadTasks(event.projectId));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onEditTask(EditTask event, Emitter<TasksState> emit) async {
    try {
      await _tasksRepository.updateTask(event.taskId, event.title, event.description);
      add(LoadTasks(event.projectId));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TasksState> emit) async {
    try {
      await _tasksRepository.deleteTask(event.taskId);
      add(LoadTasks(event.projectId));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }
}
