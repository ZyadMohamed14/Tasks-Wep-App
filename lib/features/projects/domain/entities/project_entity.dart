import 'package:equatable/equatable.dart';

class ProjectEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String creatorId;
  final DateTime createdAt;

  const ProjectEntity({
    required this.id,
    required this.name,
    this.description,
    required this.creatorId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, description, creatorId, createdAt];
}
