import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/projects/data/repositories/projects_repository_impl.dart';
import '../../features/projects/domain/repositories/projects_repository.dart';
import '../../features/projects/presentation/bloc/projects_bloc.dart';
import '../../features/tasks/data/repositories/tasks_repository_impl.dart';
import '../../features/tasks/domain/repositories/tasks_repository.dart';
import '../../features/tasks/presentation/bloc/tasks_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  sl.registerLazySingleton(() => Supabase.instance.client);

  // Features - Auth
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerFactory(() => AuthBloc(sl()));

  // Features - Projects
  sl.registerLazySingleton<ProjectsRepository>(() => ProjectsRepositoryImpl(sl()));
  sl.registerFactory(() => ProjectsBloc(sl()));

  // Features - Tasks
  sl.registerLazySingleton<TasksRepository>(() => TasksRepositoryImpl(sl()));
  sl.registerFactory(() => TasksBloc(sl()));
}
