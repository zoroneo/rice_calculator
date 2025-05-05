import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/unit.dart';
import '../models/batch.dart';
import '../models/harvest.dart';

class StorageService {
  static const String _harvestBoxName = 'harvests';
  static bool _initialized = false;

  // Initialize Hive and register adapters
  static Future<void> init() async {
    if (_initialized) return;

    try {
      await Hive.initFlutter();

      // Register adapters only if they haven't been registered yet
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(UnitAdapter());
      }

      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(BatchAdapter());
      }

      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(HarvestAdapter());
      }

      // Ensure box is closed before opening (in case it was opened incorrectly)
      if (Hive.isBoxOpen(_harvestBoxName)) {
        await Hive.box<Harvest>(_harvestBoxName).close();
      }

      // Open box
      await Hive.openBox<Harvest>(_harvestBoxName);
      _initialized = true;
      debugPrint('Hive initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Hive: $e');
      rethrow;
    }
  }

  // Load all harvests
  Future<List<Harvest>> loadHarvests() async {
    if (!_initialized) {
      await StorageService.init();
    }
    
    try {
      final box = Hive.box<Harvest>(_harvestBoxName);
      final harvests = box.values.toList();
      debugPrint('Loaded ${harvests.length} harvests from storage');
      return harvests;
    } catch (e) {
      debugPrint('Error loading harvests: $e');
      return [];
    }
  }

  // Save all harvests
  Future<void> saveHarvests(List<Harvest> harvests) async {
    if (!_initialized) {
      await StorageService.init();
    }
    
    try {
      final box = Hive.box<Harvest>(_harvestBoxName);
      
      // Clear the box first to prevent duplicates
      await box.clear();
      
      // Save each harvest with its ID as the key
      for (final harvest in harvests) {
        await box.put(harvest.id, harvest);
      }
      
      debugPrint('Saved ${harvests.length} harvests to storage');
    } catch (e) {
      debugPrint('Error saving harvests: $e');
      rethrow;
    }
  }

  // Get all harvests
  static List<Harvest> getAllHarvests() {
    if (!_initialized) {
      throw HiveError(
        'Hive not initialized. Call StorageService.init() first.',
      );
    }

    final box = Hive.box<Harvest>(_harvestBoxName);
    return box.values.toList();
  }

  // Get a single harvest by ID
  static Harvest? getHarvest(String id) {
    final box = Hive.box<Harvest>(_harvestBoxName);
    try {
      return box.get(id);
    } catch (e) {
      debugPrint('Error getting harvest: $e');
      return null;
    }
  }

  // Save a harvest (create or update)
  static Future<void> saveHarvest(Harvest harvest) async {
    final box = Hive.box<Harvest>(_harvestBoxName);
    await box.put(harvest.id, harvest);
    debugPrint('Saved harvest with ID: ${harvest.id}');
  }

  // Delete a harvest by ID
  static Future<void> deleteHarvest(String id) async {
    final box = Hive.box<Harvest>(_harvestBoxName);
    try {
      await box.delete(id);
      debugPrint('Deleted harvest with ID: $id');
    } catch (e) {
      debugPrint('Error deleting harvest: $e');
      rethrow;
    }
  }

  // Clear all data (for testing or reset)
  static Future<void> clearAllData() async {
    final box = Hive.box<Harvest>(_harvestBoxName);
    await box.clear();
    debugPrint('All data cleared');
  }
}
