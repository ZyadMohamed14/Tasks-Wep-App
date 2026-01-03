import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/tasks_repository.dart';

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
  final String? userId;
  AssignTask(this.taskId, this.userId);
  @override
  List<Object?> get props => [taskId, userId];
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
  TasksLoaded(this.tasks);
  @override
  List<Object?> get props => [tasks];
}
class TasksError extends TasksState {
  final String message;
  TasksError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class TasksBloc extends Bloc<TasksEvent, TasksState> {
  final TasksRepository _repository;

  TasksBloc(this._repository) : super(TasksInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<AddTask>(_onAddTask);
    on<MoveTask>(_onMoveTask);
    on<AssignTask>(_onAssignTask);
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TasksState> emit) async {
    emit(TasksLoading());
    try {
      final tasks = await _repository.getTasks(event.projectId);
      emit(TasksLoaded(tasks));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TasksState> emit) async {
    try {
      await _repository.createTask(event.projectId, event.title, event.description, event.status);
      add(LoadTasks(event.projectId));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onMoveTask(MoveTask event, Emitter<TasksState> emit) async {
    // Optimistic update
    if (state is TasksLoaded) {
      final currentTasks = (state as TasksLoaded).tasks;
      final updatedTasks = currentTasks.map((t) {
        if (t.id == event.task.id) {
          return t.copyWith(status: event.newStatus, position: event.newPosition);
        }
        return t;
      }).toList();
      emit(TasksLoaded(updatedTasks));
    }

    try {
      await _repository.updateTaskStatus(event.task.id, event.newStatus);
      await _repository.updateTaskPosition(event.task.id, event.newPosition);
    } catch (e) {
      // Revert on error? For now just log
      add(LoadTasks(event.task.projectId));
    }
  }

  Future<void> _onAssignTask(AssignTask event, Emitter<TasksState> emit) async {
    try {
      await _repository.assignTask(event.taskId, event.userId);
      // We need project ID to reload, or just update locally
      // For simplicity, let's assume we logicly find it or just refresh the board
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }
}
