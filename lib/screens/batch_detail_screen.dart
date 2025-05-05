import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/batch.dart';
import '../models/harvest.dart';
import '../providers/harvest_provider.dart';
import '../widgets/app_message.dart';

class BatchDetailScreen extends StatefulWidget {
  final String harvestId;
  final String batchId;

  const BatchDetailScreen({
    super.key,
    required this.harvestId,
    required this.batchId,
  });

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen> {
  // Form controllers and state
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _weightFocusNode = FocusNode();

  // Scroll and layout state
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;
  bool _showExpandedSummary = true;
  bool _isKeyboardVisible = false;

  // Edit state
  bool _isProcessing = false;
  bool _isEditing = false;
  int _editingUnitIndex = -1;

  // Formatters
  late final NumberFormat _formatter;
  late final DateFormat _dateFormatter;

  @override
  void initState() {
    super.initState();
    _formatter = NumberFormat("#,###.##");
    _dateFormatter = DateFormat('dd/MM/yyyy');
    _scrollController.addListener(_onScroll);
    _weightFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _weightFocusNode.removeListener(_onFocusChange);
    _weightFocusNode.dispose();
    super.dispose();
  }

  // Scroll and focus handlers
  void _onScroll() {
    final isCollapsed =
        _scrollController.hasClients && _scrollController.offset > 50;
    if (isCollapsed != _isCollapsed) {
      // Sử dụng addPostFrameCallback để trì hoãn việc gọi setState đến frame tiếp theo
      // Điều này tránh việc gọi setState trong quá trình bố trí
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isCollapsed = isCollapsed;
          });
        }
      });
    }
  }

  void _onFocusChange() {
    if (_weightFocusNode.hasFocus && !_isKeyboardVisible) {
      setState(() {
        _isKeyboardVisible = true;
        _showExpandedSummary = false;
      });
    } else if (!_weightFocusNode.hasFocus && _isKeyboardVisible) {
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() => _isKeyboardVisible = false);
      });
    }
  }

  // Unit CRUD operations
  Future<void> _addUnit(String harvestId, String batchId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isProcessing = true);
    try {
      final weight = double.parse(_weightController.text.trim());
      final success = await _getHarvestProvider().addUnitToBatch(
        harvestId,
        batchId,
        weight,
      );

      if (success) {
        _weightController.clear();

        // Kiểm tra xem đã đủ 5 bao chưa để tự động quay về màn hình chi tiết vụ mùa
        final currentBatch = _getHarvestProvider().harvests
            .firstWhere((h) => h.id == harvestId)
            .batches
            .firstWhere((b) => b.id == batchId);

        if (currentBatch.isFull && mounted) {
          // Quay về màn hình trước
          Navigator.of(context).pop();

          // Sau khi quay về thì hiển thị thông báo
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã thêm đủ 5 bao'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        _showMessage('Không thể thêm bao: đã đủ 5 bao trong mã này');
      }
    } catch (e) {
      _showMessage('Lỗi thêm bao: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _updateUnit(
    String harvestId,
    String batchId,
    int unitIndex,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);
    try {
      final weight = double.parse(_weightController.text.trim());
      final success = await _getHarvestProvider().updateUnitInBatch(
        harvestId,
        batchId,
        unitIndex,
        weight,
      );

      if (success) {
        _resetEditState();
      } else {
        _showMessage('Không thể cập nhật bao');
      }
    } catch (e) {
      _showMessage('Lỗi cập nhật bao: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteUnit(
    String harvestId,
    String batchId,
    int unitIndex,
  ) async {
    final confirmed = await _showConfirmationDialog(
      'Xác nhận xóa',
      'Bạn có chắc chắn muốn xóa bao này?',
    );

    if (confirmed != true) return;
    setState(() => _isProcessing = true);

    try {
      final success = await _getHarvestProvider().deleteUnitFromBatch(
        harvestId,
        batchId,
        unitIndex,
      );

      if (!success) {
        _showMessage('Không thể xóa bao');
      }
    } catch (e) {
      _showMessage('Lỗi xóa bao: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
        if (_isEditing && _editingUnitIndex == unitIndex) {
          _resetEditState();
        }
      });
    }
  }

  Future<void> _deleteBatch(String harvestId, Batch batch) async {
    final confirmed = await _showConfirmationDialog(
      'Xác nhận xóa',
      'Bạn có chắc chắn muốn xóa mã này?',
    );

    if (confirmed != true) return;
    setState(() => _isProcessing = true);

    try {
      final success = await _getHarvestProvider().deleteBatchFromHarvest(
        harvestId,
        batch.id,
      );

      if (success && mounted) {
        Navigator.of(context).pop();
      } else {
        _showMessage('Không thể xóa mã');
      }
    } catch (e) {
      _showMessage('Lỗi xóa mã: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // UI state management
  void _startEditingUnit(int index, double weight) {
    if (_isEditing && _editingUnitIndex == index) return;

    // Format the weight properly - remove decimal part if it's a whole number
    final formattedWeight =
        weight % 1 == 0 ? weight.toInt().toString() : weight.toString();
    _weightController.text = formattedWeight;

    setState(() {
      _isEditing = true;
      _editingUnitIndex = index;
      _showExpandedSummary = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(_weightFocusNode);
    });
  }

  void _cancelEditing() {
    if (!_isEditing) return;
    _resetEditState();
  }

  void _resetEditState() {
    setState(() {
      _isEditing = false;
      _editingUnitIndex = -1;
      _weightController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).unfocus();
    });
  }

  // Helper methods
  HarvestProvider _getHarvestProvider() =>
      Provider.of<HarvestProvider>(context, listen: false);

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool?> _showConfirmationDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Xóa'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HarvestProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const LoadingScaffold();
        }

        try {
          final harvest = provider.harvests.firstWhere(
            (h) => h.id == widget.harvestId,
          );
          final batch = harvest.batches.firstWhere(
            (b) => b.id == widget.batchId,
          );

          return BatchDetailScaffold(
            harvest: harvest,
            batch: batch,
            isProcessing: _isProcessing,
            isEditing: _isEditing,
            editingUnitIndex: _editingUnitIndex,
            isKeyboardVisible: _isKeyboardVisible,
            showExpandedSummary: _showExpandedSummary,
            isCollapsed: _isCollapsed,
            scrollController: _scrollController,
            formKey: _formKey,
            weightController: _weightController,
            weightFocusNode: _weightFocusNode,
            formatter: _formatter,
            dateFormatter: _dateFormatter,
            onDeleteBatch: _deleteBatch,
            onStartEditingUnit: _startEditingUnit,
            onDeleteUnit: _deleteUnit,
            onCancelEditing: _cancelEditing,
            onAddUnit: _addUnit,
            onUpdateUnit: _updateUnit,
          );
        } catch (e) {
          return ErrorScaffold(
            errorMessage: e.toString(),
            onBack: () => Navigator.of(context).pop(),
          );
        }
      },
    );
  }
}

class LoadingScaffold extends StatelessWidget {
  const LoadingScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi Tiết Mã')),
      body: const AppMessage(isLoading: true, message: 'Đang tải dữ liệu...'),
    );
  }
}

class ErrorScaffold extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onBack;

  const ErrorScaffold({
    super.key,
    required this.errorMessage,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi Tiết Mã')),
      body: AppMessage(
        isError: true,
        message: 'Lỗi: Không tìm thấy thông tin mã.\n$errorMessage',
        onRetry: onBack,
      ),
    );
  }
}

class BatchDetailScaffold extends StatelessWidget {
  final Harvest harvest;
  final Batch batch;
  final bool isProcessing;
  final bool isEditing;
  final int editingUnitIndex;
  final bool isKeyboardVisible;
  final bool showExpandedSummary;
  final bool isCollapsed;
  final ScrollController scrollController;
  final GlobalKey<FormState> formKey;
  final TextEditingController weightController;
  final FocusNode weightFocusNode;
  final NumberFormat formatter;
  final DateFormat dateFormatter;
  final Function(String, Batch) onDeleteBatch;
  final Function(int, double) onStartEditingUnit;
  final Function(String, String, int) onDeleteUnit;
  final VoidCallback onCancelEditing;
  final Function(String, String) onAddUnit;
  final Function(String, String, int) onUpdateUnit;

  const BatchDetailScaffold({
    super.key,
    required this.harvest,
    required this.batch,
    required this.isProcessing,
    required this.isEditing,
    required this.editingUnitIndex,
    required this.isKeyboardVisible,
    required this.showExpandedSummary,
    required this.isCollapsed,
    required this.scrollController,
    required this.formKey,
    required this.weightController,
    required this.weightFocusNode,
    required this.formatter,
    required this.dateFormatter,
    required this.onDeleteBatch,
    required this.onStartEditingUnit,
    required this.onDeleteUnit,
    required this.onCancelEditing,
    required this.onAddUnit,
    required this.onUpdateUnit,
  });

  bool get _shouldShowAddUnitForm {
    return (harvest.completedAt == null && !batch.isFull) || isEditing;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          isProcessing
              ? const AppMessage(isLoading: true, message: 'Đang xử lý...')
              : SafeArea(
                child: NestedScrollView(
                  controller: scrollController,
                  headerSliverBuilder:
                      (context, innerBoxIsScrolled) => [
                        BatchDetailAppBar(
                          harvest: harvest,
                          batch: batch,
                          showExpandedSummary: showExpandedSummary,
                          isCollapsed: isCollapsed,
                          innerBoxIsScrolled: innerBoxIsScrolled,
                          formatter: formatter,
                          dateFormatter: dateFormatter,
                          onDeleteBatch: onDeleteBatch,
                        ),
                      ],
                  body: UnitsList(
                    harvest: harvest,
                    batch: batch,
                    formatter: formatter,
                    isEditing: isEditing,
                    isProcessing: isProcessing,
                    onStartEditingUnit: onStartEditingUnit,
                    onDeleteUnit:
                        (index) => onDeleteUnit(harvest.id, batch.id, index),
                  ),
                ),
              ),
      bottomNavigationBar:
          _shouldShowAddUnitForm
              ? UnitForm(
                formKey: formKey,
                weightController: weightController,
                weightFocusNode: weightFocusNode,
                isEditing: isEditing,
                isProcessing: isProcessing,
                onCancelEditing: onCancelEditing,
                onAddUnit: () => onAddUnit(harvest.id, batch.id),
                onUpdateUnit:
                    () => onUpdateUnit(harvest.id, batch.id, editingUnitIndex),
              )
              : null,
    );
  }
}

class BatchDetailAppBar extends StatelessWidget {
  final Harvest harvest;
  final Batch batch;
  final bool showExpandedSummary;
  final bool isCollapsed;
  final bool innerBoxIsScrolled;
  final NumberFormat formatter;
  final DateFormat dateFormatter;
  final Function(String, Batch) onDeleteBatch;

  const BatchDetailAppBar({
    super.key,
    required this.harvest,
    required this.batch,
    required this.showExpandedSummary,
    required this.isCollapsed,
    required this.innerBoxIsScrolled,
    required this.formatter,
    required this.dateFormatter,
    required this.onDeleteBatch,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: Text('Chi Tiết Mã'),
      floating: true,
      pinned: true,
      forceElevated: innerBoxIsScrolled,
      actions: [
        if (harvest.completedAt == null)
          IconButton(
            onPressed: () => onDeleteBatch(harvest.id, batch),
            icon: const Icon(Icons.delete),
            tooltip: 'Xóa Mã',
          ),
      ],
      expandedHeight: 280,
      flexibleSpace: FlexibleSpaceBar(
        background: BatchSummary(
          harvest: harvest,
          batch: batch,
          formatter: formatter,
          dateFormatter: dateFormatter,
        ),
      ),
      bottom:
          isCollapsed
              ? PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: CollapsedSummary(batch: batch, formatter: formatter),
              )
              : null,
    );
  }
}

class CollapsedSummary extends StatelessWidget {
  final Batch batch;
  final NumberFormat formatter;

  const CollapsedSummary({
    super.key,
    required this.batch,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mã ${batch.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${batch.units.length}/${Batch.maxUnits} bao',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${formatter.format(batch.totalWeight)} kg',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (batch.isFull)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Hoàn thành',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BatchSummary extends StatelessWidget {
  final Harvest harvest;
  final Batch batch;
  final NumberFormat formatter;
  final DateFormat dateFormatter;

  const BatchSummary({
    super.key,
    required this.harvest,
    required this.batch,
    required this.formatter,
    required this.dateFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withAlpha(50),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.fromLTRB(16, 80, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            Text('Vụ mùa: ${harvest.name}'),
            Text('Ngày tạo: ${dateFormatter.format(batch.createdAt)}'),
            const Divider(),
            _buildProgressAndStats(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Mã: ${batch.name}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        if (batch.isFull)
          const Chip(
            label: Text('Hoàn thành'),
            backgroundColor: Colors.green,
            labelStyle: TextStyle(color: Colors.white),
          ),
      ],
    );
  }

  Widget _buildProgressAndStats(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thông tin tổng hợp
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Số bao: ${batch.units.length}/${Batch.maxUnits}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  'Tổng: ${formatter.format(batch.totalWeight)} kg',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Thanh tiến độ
        LinearProgressIndicator(
          value: batch.units.length / Batch.maxUnits,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            batch.isFull ? Colors.green : Theme.of(context).colorScheme.primary,
          ),
          minHeight: 8,
        ),
      ],
    );
  }
}

class UnitsList extends StatelessWidget {
  final Harvest harvest;
  final Batch batch;
  final NumberFormat formatter;
  final bool isEditing;
  final bool isProcessing;
  final Function(int, double) onStartEditingUnit;
  final Function(int) onDeleteUnit;

  const UnitsList({
    super.key,
    required this.harvest,
    required this.batch,
    required this.formatter,
    required this.isEditing,
    required this.isProcessing,
    required this.onStartEditingUnit,
    required this.onDeleteUnit,
  });

  @override
  Widget build(BuildContext context) {
    if (batch.units.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Chưa có bao nào. Hãy thêm bao mới!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    final isReadOnly = harvest.completedAt != null;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: batch.units.length,
      itemExtent: 72.0,
      itemBuilder: (context, index) {
        final unit = batch.units[index];
        return UnitListItem(
          unit: unit,
          index: index,
          isReadOnly: isReadOnly,
          isEditing: isEditing,
          isProcessing: isProcessing,
          formatter: formatter,
          onStartEditingUnit: onStartEditingUnit,
          onDeleteUnit: onDeleteUnit,
        );
      },
    );
  }
}

class UnitListItem extends StatelessWidget {
  final dynamic unit;
  final int index;
  final bool isReadOnly;
  final bool isEditing;
  final bool isProcessing;
  final NumberFormat formatter;
  final Function(int, double) onStartEditingUnit;
  final Function(int) onDeleteUnit;

  const UnitListItem({
    super.key,
    required this.unit,
    required this.index,
    required this.isReadOnly,
    required this.isEditing,
    required this.isProcessing,
    required this.formatter,
    required this.onStartEditingUnit,
    required this.onDeleteUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text('${index + 1}')),
        title: Text(
          '${formatter.format(unit.weight)} kg',
          style: const TextStyle(fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        trailing:
            isReadOnly
                ? null
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed:
                          isEditing || isProcessing
                              ? null
                              : () => onStartEditingUnit(index, unit.weight),
                      tooltip: 'Chỉnh sửa',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed:
                          isEditing || isProcessing
                              ? null
                              : () => onDeleteUnit(index),
                      tooltip: 'Xóa',
                    ),
                  ],
                ),
      ),
    );
  }
}

class UnitForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController weightController;
  final FocusNode weightFocusNode;
  final bool isEditing;
  final bool isProcessing;
  final VoidCallback onCancelEditing;
  final VoidCallback onAddUnit;
  final VoidCallback onUpdateUnit;

  const UnitForm({
    super.key,
    required this.formKey,
    required this.weightController,
    required this.weightFocusNode,
    required this.isEditing,
    required this.isProcessing,
    required this.onCancelEditing,
    required this.onAddUnit,
    required this.onUpdateUnit,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(
        left: 16,
        top: 16,
        right: 16,
        bottom: bottomInset > 0 ? bottomInset + 16 : 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            spreadRadius: 1,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: weightController,
              focusNode: weightFocusNode,
              decoration: InputDecoration(
                labelText: 'Cân nặng (kg)',
                border: const OutlineInputBorder(),
                suffixText: 'kg',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: bottomInset > 0 ? 8 : 12,
                ),
                suffixIcon:
                    isEditing
                        ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: onCancelEditing,
                        )
                        : null,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              autofocus: true,
              validator: _validateWeight,
              onFieldSubmitted: (_) => _submitForm(),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: isProcessing ? null : _submitForm,
              child: Text(isEditing ? 'Cập Nhật Bao' : 'Thêm Bao'),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập cân nặng';
    }
    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Vui lòng nhập số hợp lệ';
    }
    if (weight <= 0) {
      return 'Cân nặng phải lớn hơn 0';
    }
    return null;
  }

  void _submitForm() {
    if (isEditing) {
      onUpdateUnit();
    } else {
      onAddUnit();
    }
  }
}
