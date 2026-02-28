import '../../domain/entities/h_e_l_l_o_entity.dart';

class HelloModel extends HelloEntity {
  const HelloModel({
    required super.id,
    required super.name,
    required super.createdAt,
  });

  factory HelloModel.fromJson(Map<String, dynamic> json) {
    return HelloModel(
      id: json[''],
      name: json[''],
      createdAt: json[''],
    );
  }

  Map<String, dynamic> toJson() => {
      '': id,
      '': name,
      '': createdAt,
  };

  factory HelloModel.fromEntity(HelloEntity entity) {
    return HelloModel(
      id: entity.id,
      name: entity.name,
      createdAt: entity.createdAt,
    );
  }
}
