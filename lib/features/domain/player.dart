import 'package:equatable/equatable.dart';

class Player extends Equatable {
  final int? id;
  final String name;
  final String? photoPath;
  final DateTime createdAt;

  const Player({
    this.id,
    required this.name,
    this.photoPath,
    required this.createdAt,
  });

  Player copyWith({
    int? id,
    String? name,
    String? photoPath,
    DateTime? createdAt,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'photo_path': photoPath,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as int?,
      name: map['name'] as String,
      photoPath: map['photo_path'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  @override
  List<Object?> get props => [id, name, photoPath, createdAt];
}

