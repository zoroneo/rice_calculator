import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/harvest.dart';
import '../services/storage_service.dart';

class HarvestProvider with ChangeNotifier {
  final StorageService _storageService;
  List<Harvest> _harvests = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  HarvestProvider(this._storageService);

  // Getters
  List<Harvest> get harvests => List.unmodifiable(_harvests);
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  // Initialize provider and load data
  Future<void> initialize() async {
    if (_isLoading) return;
    
    _setLoading(true);
    try {
      _harvests = await _storageService.loadHarvests();
      _clearError();
    } catch (e) {
      _setError('Không thể tải dữ liệu: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Create a new harvest
  Future<String> createHarvest({
    required String name,
    required double unitPrice,
    required double bagDeduction,
  }) async {
    _setLoading(true);
    try {
      final harvest = Harvest.create(
        name: name,
        unitPrice: unitPrice,
        bagDeduction: bagDeduction,
      );
      
      _harvests.add(harvest);
      await _saveData();
      
      _clearError();
      return harvest.id;
    } catch (e) {
      _setError('Không thể tạo vụ mới: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Add a harvest (alias for createHarvest with simpler parameters)
  Future<String> addHarvest(
    String name,
    double unitPrice,
    double bagDeduction,
  ) async {
    return createHarvest(
      name: name,
      unitPrice: unitPrice,
      bagDeduction: bagDeduction,
    );
  }

  // Update an existing harvest
  Future<bool> updateHarvest({
    required String id,
    String? name,
    double? unitPrice,
    double? bagDeduction,
  }) async {
    _setLoading(true);
    try {
      final index = _harvests.indexWhere((h) => h.id == id);
      if (index < 0) {
        _setError('Không tìm thấy vụ với ID: $id');
        return false;
      }
      
      final harvest = _harvests[index];
      final updatedHarvest = harvest.copyWith(
        name: name,
        unitPrice: unitPrice,
        bagDeduction: bagDeduction,
      );
      
      _harvests[index] = updatedHarvest;
      await _saveData();
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Không thể cập nhật vụ: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a harvest
  Future<bool> deleteHarvest(String id) async {
    _setLoading(true);
    try {
      final index = _harvests.indexWhere((h) => h.id == id);
      if (index < 0) {
        _setError('Không tìm thấy vụ với ID: $id');
        return false;
      }
      
      _harvests.removeAt(index);
      await _saveData();
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Không thể xóa vụ: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mark a harvest as completed
  Future<bool> completeHarvest(String id) async {
    _setLoading(true);
    try {
      final index = _harvests.indexWhere((h) => h.id == id);
      if (index < 0) {
        _setError('Không tìm thấy vụ với ID: $id');
        return false;
      }
      
      final harvest = _harvests[index];
      _harvests[index] = harvest.complete();
      await _saveData();
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Không thể hoàn thành vụ: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Add a new batch to a harvest
  Future<String?> addBatchToHarvest(String harvestId) async {
    _setLoading(true);
    try {
      final index = _harvests.indexWhere((h) => h.id == harvestId);
      if (index < 0) {
        _setError('Không tìm thấy vụ với ID: $harvestId');
        return null;
      }
      
      final harvest = _harvests[index];
      if (harvest.completedAt != null) {
        _setError('Không thể thêm mã cho vụ đã hoàn thành');
        return null;
      }
      
      final batch = harvest.addBatch();
      await _saveData();
      
      _clearError();
      return batch.id;
    } catch (e) {
      _setError('Không thể thêm mã mới: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a batch from a harvest
  Future<bool> deleteBatchFromHarvest(String harvestId, String batchId) async {
    _setLoading(true);
    try {
      final index = _harvests.indexWhere((h) => h.id == harvestId);
      if (index < 0) {
        _setError('Không tìm thấy vụ với ID: $harvestId');
        return false;
      }
      
      final harvest = _harvests[index];
      if (harvest.completedAt != null) {
        _setError('Không thể xóa mã từ vụ đã hoàn thành');
        return false;
      }
      
      if (!harvest.removeBatch(batchId)) {
        _setError('Không tìm thấy mã với ID: $batchId');
        return false;
      }
      
      await _saveData();
      _clearError();
      return true;
    } catch (e) {
      _setError('Không thể xóa mã: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Add a unit to a batch
  Future<bool> addUnitToBatch(
    String harvestId, 
    String batchId, 
    double weight,
  ) async {
    _setLoading(true);
    try {
      final harvestIndex = _harvests.indexWhere((h) => h.id == harvestId);
      if (harvestIndex < 0) {
        _setError('Không tìm thấy vụ với ID: $harvestId');
        return false;
      }
      
      final harvest = _harvests[harvestIndex];
      if (harvest.completedAt != null) {
        _setError('Không thể thêm bao cho vụ đã hoàn thành');
        return false;
      }
      
      if (!harvest.addUnitToBatch(batchId, weight)) {
        _setError('Không thể thêm bao: mã đã đủ hoặc không tìm thấy');
        return false;
      }
      
      await _saveData();
      _clearError();
      return true;
    } catch (e) {
      _setError('Không thể thêm bao: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update a unit in a batch
  Future<bool> updateUnitInBatch(
    String harvestId,
    String batchId,
    int unitIndex,
    double weight,
  ) async {
    _setLoading(true);
    try {
      final harvestIndex = _harvests.indexWhere((h) => h.id == harvestId);
      if (harvestIndex < 0) {
        _setError('Không tìm thấy vụ với ID: $harvestId');
        return false;
      }
      
      final harvest = _harvests[harvestIndex];
      if (harvest.completedAt != null) {
        _setError('Không thể cập nhật bao cho vụ đã hoàn thành');
        return false;
      }
      
      if (!harvest.updateUnitInBatch(batchId, unitIndex, weight)) {
        _setError('Không thể cập nhật bao: không tìm thấy');
        return false;
      }
      
      await _saveData();
      _clearError();
      return true;
    } catch (e) {
      _setError('Không thể cập nhật bao: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a unit from a batch
  Future<bool> deleteUnitFromBatch(
    String harvestId,
    String batchId,
    int unitIndex,
  ) async {
    _setLoading(true);
    try {
      final harvestIndex = _harvests.indexWhere((h) => h.id == harvestId);
      if (harvestIndex < 0) {
        _setError('Không tìm thấy vụ với ID: $harvestId');
        return false;
      }
      
      final harvest = _harvests[harvestIndex];
      if (harvest.completedAt != null) {
        _setError('Không thể xóa bao từ vụ đã hoàn thành');
        return false;
      }
      
      if (!harvest.removeUnitFromBatch(batchId, unitIndex)) {
        _setError('Không thể xóa bao: không tìm thấy');
        return false;
      }
      
      await _saveData();
      _clearError();
      return true;
    } catch (e) {
      _setError('Không thể xóa bao: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Save the current data to storage
  Future<void> _saveData() async {
    try {
      await _storageService.saveHarvests(_harvests);
    } catch (e) {
      _setError('Không thể lưu dữ liệu: ${e.toString()}');
      rethrow;
    }
  }

  // Helper methods for state management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _hasError = true;
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }
}
