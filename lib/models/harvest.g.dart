// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'harvest.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HarvestAdapter extends TypeAdapter<Harvest> {
  @override
  final int typeId = 3;

  @override
  Harvest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Harvest(
      id: fields[0] as String,
      name: fields[1] as String,
      unitPrice: fields[2] as double,
      bagDeduction: fields[3] as double,
      createdAt: fields[4] as DateTime,
      completedAt: fields[5] as DateTime?,
      batches: (fields[6] as List).cast<Batch>(),
    );
  }

  @override
  void write(BinaryWriter writer, Harvest obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.unitPrice)
      ..writeByte(3)
      ..write(obj.bagDeduction)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.completedAt)
      ..writeByte(6)
      ..write(obj.batches);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HarvestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Harvest _$HarvestFromJson(Map<String, dynamic> json) => Harvest(
      id: json['id'] as String,
      name: json['name'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      bagDeduction: (json['bagDeduction'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      batches: (json['batches'] as List<dynamic>)
          .map((e) => Batch.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$HarvestToJson(Harvest instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'unitPrice': instance.unitPrice,
      'bagDeduction': instance.bagDeduction,
      'createdAt': instance.createdAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'batches': instance.batches,
    };
