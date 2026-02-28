import 'package:equatable/equatable.dart';

class HelloEntity extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;

  const HelloEntity({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  HelloEntity copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return HelloEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, createdAt];
}
