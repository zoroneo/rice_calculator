// ignore: depend_on_referenced_packages
import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'batch.dart';
import 'unit.dart';

part 'harvest.g.dart';

@HiveType(typeId: 3)
@JsonSerializable()
class Harvest {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final double unitPrice;
  
  @HiveField(3)
  final double bagDeduction;
  
  @HiveField(4)
  final DateTime createdAt;
  
  @HiveField(5)
  final DateTime? completedAt;
  
  @HiveField(6)
  final List<Batch> batches;

  Harvest({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.bagDeduction,
    required this.createdAt,
    this.completedAt,
    required this.batches,
  });

  // Create a new harvest
  factory Harvest.create({
    required String name,
    required double unitPrice,
    required double bagDeduction,
  }) {
    return Harvest(
      id: const Uuid().v4(),
      name: name,
      unitPrice: unitPrice,
      bagDeduction: bagDeduction,
      createdAt: DateTime.now(),
      completedAt: null,
      batches: [],
    );
  }

  // Create a copy of this harvest with updated fields
  Harvest copyWith({
    String? id,
    String? name,
    double? unitPrice,
    double? bagDeduction,
    DateTime? createdAt,
    DateTime? completedAt,
    List<Batch>? batches,
    bool clearCompletedAt = false,
  }) {
    return Harvest(
      id: id ?? this.id,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      bagDeduction: bagDeduction ?? this.bagDeduction,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      batches: batches ?? List.from(this.batches),
    );
  }

  // Mark this harvest as completed
  Harvest complete() {
    return copyWith(completedAt: DateTime.now());
  }

  // Add a new batch to this harvest
  Batch addBatch() {
    // Generate a new batch number by using the current length + 1
    final batchNumber = batches.length + 1;
    final batch = Batch.create(
      id: const Uuid().v4(), 
      batchNumber: batchNumber,
    );
    
    batches.add(batch);
    return batch;
  }
  
  // Remove a batch from this harvest
  bool removeBatch(String batchId) {
    final index = batches.indexWhere((b) => b.id == batchId);
    if (index < 0) {
      return false;
    }
    batches.removeAt(index);
    return true;
  }

  // Add a unit to a specific batch
  bool addUnitToBatch(String batchId, double weight) {
    final batchIndex = batches.indexWhere((b) => b.id == batchId);
    if (batchIndex < 0) {
      return false;
    }
    
    final batch = batches[batchIndex];
    if (batch.isFull) {
      return false;
    }
    
    final unit = Unit(
      id: const Uuid().v4(),
      weight: weight,
      createdAt: DateTime.now(),
    );
    
    final updatedBatch = batch.copyWith(
      units: [...batch.units, unit],
    );
    
    batches[batchIndex] = updatedBatch;
    return true;
  }

  // Update a unit in a specific batch
  bool updateUnitInBatch(String batchId, int unitIndex, double weight) {
    final batchIndex = batches.indexWhere((b) => b.id == batchId);
    if (batchIndex < 0) {
      return false;
    }
    
    final batch = batches[batchIndex];
    if (unitIndex < 0 || unitIndex >= batch.units.length) {
      return false;
    }
    
    final updatedBatch = batch.updateUnit(unitIndex, weight);
    batches[batchIndex] = updatedBatch;
    return true;
  }

  // Remove a unit from a specific batch
  bool removeUnitFromBatch(String batchId, int unitIndex) {
    final batchIndex = batches.indexWhere((b) => b.id == batchId);
    if (batchIndex < 0) {
      return false;
    }
    
    final batch = batches[batchIndex];
    if (unitIndex < 0 || unitIndex >= batch.units.length) {
      return false;
    }
    
    final updatedBatch = batch.removeUnit(unitIndex);
    batches[batchIndex] = updatedBatch;
    return true;
  }

  // Get the total number of bags across all batches
  int get totalBags => batches.fold(
    0, (sum, batch) => sum + batch.units.length
  );

  // Get the total weight across all batches
  double get totalWeight => batches.fold(
    0.0, (sum, batch) => sum + batch.totalWeight
  );

  // Get the total deduction for all bags
  double get totalDeduction => totalBags * bagDeduction;

  // Get the net weight after deduction
  double get netWeight => totalWeight - totalDeduction;

  // Get the total payment amount
  double get totalPayment => netWeight * unitPrice;

  // JSON serialization
  factory Harvest.fromJson(Map<String, dynamic> json) => _$HarvestFromJson(json);
  Map<String, dynamic> toJson() => _$HarvestToJson(this);
}