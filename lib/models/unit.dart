import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:json_annotation/json_annotation.dart';

part 'unit.g.dart';

@JsonSerializable()
@HiveType(typeId: 1)
class Unit extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double weight;

  @HiveField(2)
  final DateTime createdAt;

  Unit({String? id, required this.weight, DateTime? createdAt})
    : id = id ?? const Uuid().v4(),
      createdAt = createdAt ?? DateTime.now();
      
  /// Connect the generated [_$UnitFromJson] function to the class.
  factory Unit.fromJson(Map<String, dynamic> json) => _$UnitFromJson(json);

  /// Connect the generated [_$UnitToJson] function to the class.
  Map<String, dynamic> toJson() => _$UnitToJson(this);
}
