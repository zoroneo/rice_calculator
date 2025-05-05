// ignore: depend_on_referenced_packages
import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';
import 'unit.dart';

part 'batch.g.dart';

@HiveType(typeId: 2)
@JsonSerializable()
class Batch {
  static const int maxUnits = 5; // Maximum number of units per batch

  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final DateTime createdAt;
  
  @HiveField(3)
  final List<Unit> units;

  Batch({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.units,
  });

  // Create a new batch with auto-generated name
  factory Batch.create({required String id, required int batchNumber}) {
    return Batch(
      id: id,
      name: batchNumber.toString(), // The batch name is just its number
      createdAt: DateTime.now(),
      units: [],
    );
  }

  // Add a unit to this batch if it's not full
  bool addUnit(Unit unit) {
    if (units.length >= maxUnits) {
      return false; // Batch is already full
    }
    units.add(unit);
    return true;
  }

  // Get the total weight of all units in this batch
  double get totalWeight => units.fold(0, (sum, unit) => sum + unit.weight);

  // Check if the batch has reached the maximum number of units
  bool get isFull => units.length >= maxUnits;

  // Create a copy of this batch with updated data
  Batch copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<Unit>? units,
  }) {
    return Batch(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      units: units ?? List.from(this.units),
    );
  }

  // Update a unit at specific index
  Batch updateUnit(int index, double weight) {
    if (index < 0 || index >= units.length) {
      return this; // Index out of bounds
    }
    final updatedUnits = List<Unit>.from(units);
    updatedUnits[index] = Unit(
      id: units[index].id,
      weight: weight,
      createdAt: units[index].createdAt,
    );
    return copyWith(units: updatedUnits);
  }

  // Remove a unit at specific index
  Batch removeUnit(int index) {
    if (index < 0 || index >= units.length) {
      return this; // Index out of bounds
    }
    final updatedUnits = List<Unit>.from(units);
    updatedUnits.removeAt(index);
    return copyWith(units: updatedUnits);
  }

  // JSON serialization
  factory Batch.fromJson(Map<String, dynamic> json) => _$BatchFromJson(json);
  Map<String, dynamic> toJson() => _$BatchToJson(this);
}
