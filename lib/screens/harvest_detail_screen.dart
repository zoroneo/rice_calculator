import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/harvest_provider.dart';
import '../models/harvest.dart';
import '../models/batch.dart';
import '../widgets/app_message.dart';
import 'batch_detail_screen.dart';

class HarvestDetailScreen extends StatefulWidget {
  final String harvestId;

  const HarvestDetailScreen({super.key, required this.harvestId});

  @override
  State<HarvestDetailScreen> createState() => _HarvestDetailScreenState();
}

class _HarvestDetailScreenState extends State<HarvestDetailScreen> {
  bool _isEditing = false;
  bool _isProcessing = false;
  bool _isDialogOpen = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _deductionController;
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  // Các thuộc tính cho bộ lọc batch
  String _filterMode = 'all'; // 'all', 'completed', 'incomplete'
  String _sortMode = 'name'; // 'name', 'weight'
  bool _sortAscending = true;
  TextEditingController _searchController = TextEditingController();
  bool _showFilterOptions = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _deductionController = TextEditingController();
    _searchController = TextEditingController();

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _deductionController.dispose();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isCollapsed =
        _scrollController.hasClients && _scrollController.offset > 50;
    if (isCollapsed != _isCollapsed) {
      // Use addPostFrameCallback to defer the setState call to the next frame
      // This avoids calling setState during layout
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isCollapsed = isCollapsed;
          });
        }
      });
    }
  }

  // Initialize form controllers with harvest data
  void _initializeFormControllers(Harvest harvest) {
    _nameController.text = harvest.name;
    _priceController.text = harvest.unitPrice.toString();
    _deductionController.text = harvest.bagDeduction.toString();
  }

  // Add a new batch to the harvest
  Future<void> _addBatch(BuildContext context, String harvestId) async {
    if (_isDialogOpen) return;

    setState(() {
      _isProcessing = true;
      _isDialogOpen = true;
    });

    try {
      final batchId = await Provider.of<HarvestProvider>(
        context,
        listen: false,
      ).addBatchToHarvest(harvestId);

      if (context.mounted && batchId != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) =>
                    BatchDetailScreen(harvestId: harvestId, batchId: batchId),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo mã mới: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isDialogOpen = false;
        });
      }
    }
  }

  // Save edited harvest details
  Future<void> _saveHarvest(BuildContext context, String id) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final name = _nameController.text.trim();
        final price = double.parse(_priceController.text.trim());
        final deduction = double.parse(_deductionController.text.trim());

        await Provider.of<HarvestProvider>(
          context,
          listen: false,
        ).updateHarvest(
          id: id,
          name: name,
          unitPrice: price,
          bagDeduction: deduction,
        );

        if (context.mounted) {
          setState(() {
            _isEditing = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã cập nhật vụ mùa')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi cập nhật vụ mùa: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  // Mark harvest as complete
  Future<void> _completeHarvest(BuildContext context, String id) async {
    if (_isDialogOpen) return;

    setState(() {
      _isDialogOpen = true;
    });

    // Hiển thị dialog xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác nhận hoàn thành'),
            content: const Text(
              'Bạn có chắc chắn muốn hoàn thành vụ mùa này không? Sau khi hoàn thành, bạn không thể thêm mới hoặc chỉnh sửa dữ liệu của vụ mùa này.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                child: const Text('Xác nhận hoàn thành'),
              ),
            ],
          ),
    );

    setState(() {
      _isDialogOpen = false;
    });

    if (confirmed ?? false) {
      setState(() {
        _isProcessing = true;
      });

      try {
        if (!context.mounted) return;

        await Provider.of<HarvestProvider>(
          context,
          listen: false,
        ).completeHarvest(id);

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã hoàn thành vụ mùa')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi hoàn thành vụ mùa: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  // Delete a harvest after confirmation
  Future<void> _deleteHarvest(
    BuildContext context,
    String id,
    String name,
  ) async {
    if (_isDialogOpen) return;

    setState(() {
      _isDialogOpen = true;
    });

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: Text(
              'Bạn có chắc chắn muốn xóa vụ mùa "$name" không? Hành động này không thể hoàn tác.',
            ),
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

    setState(() {
      _isDialogOpen = false;
    });

    if (confirmed ?? false) {
      setState(() {
        _isProcessing = true;
      });

      try {
        if (context.mounted) {
          await Provider.of<HarvestProvider>(
            context,
            listen: false,
          ).deleteHarvest(id);
        }
        if (context.mounted) {
          Navigator.of(context).pop(); // Return to Home screen
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã xóa vụ mùa')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa vụ mùa: ${e.toString()}')),
          );
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  // Delete a batch after confirmation
  Future<void> _deleteBatch(
    BuildContext context,
    String harvestId,
    Batch batch,
  ) async {
    if (_isDialogOpen) return;

    setState(() {
      _isDialogOpen = true;
    });

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác nhận xóa mã'),
            content: Text(
              'Bạn có chắc chắn muốn xóa mã "${batch.name}" không? Mọi dữ liệu bao trong mã này sẽ bị mất.',
            ),
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

    setState(() {
      _isDialogOpen = false;
    });

    if (confirmed ?? false) {
      setState(() {
        _isProcessing = true;
      });

      try {
        if (context.mounted) {
          await Provider.of<HarvestProvider>(
            context,
            listen: false,
          ).deleteBatchFromHarvest(harvestId, batch.id);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã xóa mã')));
          setState(() {
            _isProcessing = false;
          });
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa mã: ${e.toString()}')),
          );
          setState(() {
            _isProcessing = false;
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  // Filter and sort batches based on current filter settings
  List<Batch> _getFilteredBatches(Harvest harvest) {
    List<Batch> filteredBatches = List.from(harvest.batches);

    // Áp dụng bộ lọc theo trạng thái hoàn thành
    if (_filterMode == 'completed') {
      filteredBatches = filteredBatches.where((batch) => batch.isFull).toList();
    } else if (_filterMode == 'incomplete') {
      filteredBatches =
          filteredBatches.where((batch) => !batch.isFull).toList();
    }

    // Áp dụng tìm kiếm theo tên
    if (_searchController.text.isNotEmpty) {
      final searchQuery = _searchController.text.toLowerCase();
      filteredBatches =
          filteredBatches
              .where((batch) => batch.name.toLowerCase().contains(searchQuery))
              .toList();
    }

    // Sắp xếp theo tiêu chí đã chọn
    filteredBatches.sort((a, b) {
      if (_sortMode == 'name') {
        return _sortAscending
            ? a.name.compareTo(b.name)
            : b.name.compareTo(a.name);
      } else {
        // weight
        return _sortAscending
            ? a.totalWeight.compareTo(b.totalWeight)
            : b.totalWeight.compareTo(a.totalWeight);
      }
    });

    return filteredBatches;
  }

  // Hiển thị dialog bộ lọc và sắp xếp
  void _showFilterDialog(BuildContext context) {
    // Lưu trữ tạm thời các giá trị lọc hiện tại
    String tempFilterMode = _filterMode;
    String tempSortMode = _sortMode;
    bool tempSortAscending = _sortAscending;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Lọc và Sắp xếp'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lọc theo trạng thái:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<String>(
                      title: const Text('Tất cả'),
                      value: 'all',
                      groupValue: tempFilterMode,
                      onChanged: (value) {
                        setState(() {
                          tempFilterMode = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Đã hoàn thành'),
                      value: 'completed',
                      groupValue: tempFilterMode,
                      onChanged: (value) {
                        setState(() {
                          tempFilterMode = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Chưa hoàn thành'),
                      value: 'incomplete',
                      groupValue: tempFilterMode,
                      onChanged: (value) {
                        setState(() {
                          tempFilterMode = value!;
                        });
                      },
                    ),
                    const Divider(),
                    const Text(
                      'Sắp xếp theo:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<String>(
                      title: const Text('Tên mã'),
                      value: 'name',
                      groupValue: tempSortMode,
                      onChanged: (value) {
                        setState(() {
                          tempSortMode = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Trọng lượng'),
                      value: 'weight',
                      groupValue: tempSortMode,
                      onChanged: (value) {
                        setState(() {
                          tempSortMode = value!;
                        });
                      },
                    ),
                    const Divider(),
                    const Text(
                      'Thứ tự sắp xếp:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<bool>(
                      title: const Text('Tăng dần'),
                      value: true,
                      groupValue: tempSortAscending,
                      onChanged: (value) {
                        setState(() {
                          tempSortAscending = value!;
                        });
                      },
                    ),
                    RadioListTile<bool>(
                      title: const Text('Giảm dần'),
                      value: false,
                      groupValue: tempSortAscending,
                      onChanged: (value) {
                        setState(() {
                          tempSortAscending = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Đóng dialog mà không lưu
                  },
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Cập nhật các giá trị lọc chính khi người dùng xác nhận
                    this.setState(() {
                      _filterMode = tempFilterMode;
                      _sortMode = tempSortMode;
                      _sortAscending = tempSortAscending;
                    });
                    Navigator.of(context).pop(); // Đóng dialog
                  },
                  child: const Text('Áp dụng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HarvestProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi Tiết Vụ Mùa')),
            body: const AppMessage(
              isLoading: true,
              message: 'Đang tải dữ liệu...',
            ),
          );
        }

        try {
          final harvest = provider.harvests.firstWhere(
            (h) => h.id == widget.harvestId,
          );

          // Initialize controllers if editing
          if (_isEditing && _nameController.text.isEmpty) {
            _initializeFormControllers(harvest);
          }

          return Scaffold(
            body:
                _isProcessing
                    ? const AppMessage(
                      isLoading: true,
                      message: 'Đang xử lý...',
                    )
                    : SafeArea(
                      child: NestedScrollView(
                        controller: _scrollController,
                        headerSliverBuilder: (context, innerBoxIsScrolled) {
                          return [
                            SliverAppBar(
                              title: Text(
                                _isEditing
                                    ? 'Chỉnh Sửa Vụ Mùa'
                                    : 'Chi Tiết Vụ Mùa',
                              ),
                              floating: true,
                              pinned: true,
                              forceElevated: innerBoxIsScrolled,
                              actions: [
                                if (!_isEditing && harvest.completedAt == null)
                                  IconButton(
                                    onPressed:
                                        _isProcessing
                                            ? null
                                            : () => setState(
                                              () => _isEditing = true,
                                            ),
                                    tooltip: 'Chỉnh Sửa',
                                    icon: const Icon(Icons.edit),
                                  ),
                                if (!_isEditing)
                                  IconButton(
                                    onPressed:
                                        _isProcessing || _isEditing
                                            ? null
                                            : () => _deleteHarvest(
                                              context,
                                              harvest.id,
                                              harvest.name,
                                            ),
                                    tooltip: 'Xóa Vụ Mùa',
                                    icon: const Icon(Icons.delete),
                                  ),
                              ],
                              expandedHeight: _isEditing ? 0 : 380,
                              flexibleSpace:
                                  _isEditing
                                      ? null
                                      : FlexibleSpaceBar(
                                        background: HarvestSummaryWidget(
                                          harvest: harvest,
                                          onComplete:
                                              () => _completeHarvest(
                                                context,
                                                harvest.id,
                                              ),
                                          isProcessing: _isProcessing,
                                        ),
                                      ),
                              bottom:
                                  _isCollapsed && !_isEditing
                                      ? PreferredSize(
                                        preferredSize: const Size.fromHeight(
                                          kToolbarHeight,
                                        ),
                                        child: CollapsedSummaryWidget(
                                          harvest: harvest,
                                        ),
                                      )
                                      : null,
                            ),
                          ];
                        },
                        body:
                            _isEditing
                                ? HarvestEditForm(
                                  harvest: harvest,
                                  formKey: _formKey,
                                  nameController: _nameController,
                                  priceController: _priceController,
                                  deductionController: _deductionController,
                                  onSave:
                                      () => _saveHarvest(context, harvest.id),
                                  onCancel:
                                      () => setState(() => _isEditing = false),
                                )
                                : BatchesContent(
                                  harvest: harvest,
                                  filterMode: _filterMode,
                                  sortMode: _sortMode,
                                  sortAscending: _sortAscending,
                                  searchController: _searchController,
                                  showFilterOptions: _showFilterOptions,
                                  onShowFilterOptionsChanged:
                                      (value) => setState(
                                        () => _showFilterOptions = value,
                                      ),
                                  onShowFilterDialog:
                                      () => _showFilterDialog(context),
                                  getFilteredBatches: _getFilteredBatches,
                                  onDeleteBatch:
                                      (batch) => _deleteBatch(
                                        context,
                                        harvest.id,
                                        batch,
                                      ),
                                ),
                      ),
                    ),
            floatingActionButton:
                !_isEditing && harvest.completedAt == null
                    ? FloatingActionButton(
                      heroTag:
                          'harvest_detail_${harvest.id}_${DateTime.now().millisecondsSinceEpoch}',
                      onPressed:
                          _isProcessing
                              ? null
                              : () => _addBatch(context, harvest.id),
                      tooltip: 'Thêm Mã Mới',
                      child: const Icon(Icons.add),
                    )
                    : null,
          );
        } catch (e) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi Tiết Vụ Mùa')),
            body: AppMessage(
              isError: true,
              message: 'Lỗi: Không tìm thấy thông tin vụ mùa.\n${e.toString()}',
              onRetry: () => Navigator.of(context).pop(),
            ),
          );
        }
      },
    );
  }
}

// Widget hiển thị tóm tắt khi cuộn xuống
class CollapsedSummaryWidget extends StatelessWidget {
  final Harvest harvest;

  const CollapsedSummaryWidget({super.key, required this.harvest});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,###.##");
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
                  harvest.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${harvest.totalBags} bao - ${formatter.format(harvest.netWeight)} kg',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '₫${formatter.format(harvest.totalPayment)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget hiển thị thông tin tóm tắt vụ mùa
class HarvestSummaryWidget extends StatelessWidget {
  final Harvest harvest;
  final VoidCallback onComplete;
  final bool isProcessing;

  const HarvestSummaryWidget({
    super.key,
    required this.harvest,
    required this.onComplete,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,###.##");
    final dateFormatter = DateFormat('dd/MM/yyyy');

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    harvest.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (harvest.completedAt != null)
                  const Chip(
                    label: Text('Đã hoàn thành'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Ngày tạo: ${dateFormatter.format(harvest.createdAt)}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Giá: ₫${formatter.format(harvest.unitPrice)}/kg',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Trừ bì: ${harvest.bagDeduction} kg/bao',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tổng bao: ${harvest.totalBags}'),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tổng cân: ${formatter.format(harvest.totalWeight)} kg',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Trừ bì: ${formatter.format(harvest.totalDeduction)} kg',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tịnh: ${formatter.format(harvest.netWeight)} kg',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Thành tiền: ₫${formatter.format(harvest.totalPayment)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            if (harvest.completedAt == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: isProcessing ? null : onComplete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline),
                          SizedBox(width: 8),
                          Text('Hoàn Thành Vụ Mùa'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Widget biểu mẫu chỉnh sửa vụ mùa
class HarvestEditForm extends StatelessWidget {
  final Harvest harvest;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController deductionController;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const HarvestEditForm({
    super.key,
    required this.harvest,
    required this.formKey,
    required this.nameController,
    required this.priceController,
    required this.deductionController,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên Vụ Mùa',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên vụ mùa';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Giá mỗi kg (₫)',
                      border: OutlineInputBorder(),
                      prefixText: '₫ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập giá';
                      }
                      final price = double.tryParse(value);
                      if (price == null) {
                        return 'Số không hợp lệ';
                      }
                      if (price <= 0) {
                        return 'Giá phải > 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: deductionController,
                    decoration: const InputDecoration(
                      labelText: 'Trừ Bì (kg/bao)',
                      border: OutlineInputBorder(),
                      suffixText: 'kg',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập trừ bì';
                      }
                      final deduction = double.tryParse(value);
                      if (deduction == null) {
                        return 'Số không hợp lệ';
                      }
                      if (deduction < 0) {
                        return 'Không thể < 0';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onCancel, child: const Text('Hủy')),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: onSave, child: const Text('Lưu')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget hiển thị nội dung các mã (batches)
class BatchesContent extends StatelessWidget {
  final Harvest harvest;
  final String filterMode;
  final String sortMode;
  final bool sortAscending;
  final TextEditingController searchController;
  final bool showFilterOptions;
  final Function(bool) onShowFilterOptionsChanged;
  final VoidCallback onShowFilterDialog;
  final List<Batch> Function(Harvest) getFilteredBatches;
  final Function(Batch) onDeleteBatch;

  const BatchesContent({
    super.key,
    required this.harvest,
    required this.filterMode,
    required this.sortMode,
    required this.sortAscending,
    required this.searchController,
    required this.showFilterOptions,
    required this.onShowFilterOptionsChanged,
    required this.onShowFilterDialog,
    required this.getFilteredBatches,
    required this.onDeleteBatch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BatchesHeader(
          harvest: harvest,
          filterMode: filterMode,
          sortMode: sortMode,
          sortAscending: sortAscending,
          searchController: searchController,
          showFilterOptions: showFilterOptions,
          onShowFilterOptionsChanged: onShowFilterOptionsChanged,
          onShowFilterDialog: onShowFilterDialog,
        ),
        Expanded(
          child: BatchesGrid(
            harvest: harvest,
            filteredBatches: getFilteredBatches(harvest),
            onDeleteBatch: onDeleteBatch,
          ),
        ),
      ],
    );
  }
}

// Widget hiển thị tiêu đề và bộ lọc cho các mã
class BatchesHeader extends StatelessWidget {
  final Harvest harvest;
  final String filterMode;
  final String sortMode;
  final bool sortAscending;
  final TextEditingController searchController;
  final bool showFilterOptions;
  final Function(bool) onShowFilterOptionsChanged;
  final VoidCallback onShowFilterDialog;

  const BatchesHeader({
    super.key,
    required this.harvest,
    required this.filterMode,
    required this.sortMode,
    required this.sortAscending,
    required this.searchController,
    required this.showFilterOptions,
    required this.onShowFilterOptionsChanged,
    required this.onShowFilterDialog,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Danh Sách Mã (${harvest.batches.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  // Nút tìm kiếm
                  IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: 'Tìm kiếm',
                    onPressed: () {
                      onShowFilterOptionsChanged(!showFilterOptions);
                    },
                  ),
                  // Nút lọc
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    tooltip: 'Lọc và sắp xếp',
                    onPressed: onShowFilterDialog,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Trường tìm kiếm
        if (showFilterOptions)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm mã...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            onShowFilterOptionsChanged(true);
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                // setState được xử lý ở lớp cha
              },
            ),
          ),
        // Hiển thị các bộ lọc đang kích hoạt
        if (filterMode != 'all' || sortMode != 'name' || !sortAscending)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (filterMode != 'all')
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(
                          filterMode == 'completed'
                              ? 'Đã hoàn thành'
                              : 'Chưa hoàn thành',
                        ),
                        onDeleted: () {
                          // onFilterModeChanged('all') - được xử lý ở lớp cha
                        },
                      ),
                    ),
                  Chip(
                    label: Text(
                      'Sắp xếp: ${sortMode == 'name' ? 'Tên' : 'Trọng lượng'} ${sortAscending ? '↑' : '↓'}',
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// Widget hiển thị lưới các mã
class BatchesGrid extends StatelessWidget {
  final Harvest harvest;
  final List<Batch> filteredBatches;
  final Function(Batch) onDeleteBatch;

  const BatchesGrid({
    super.key,
    required this.harvest,
    required this.filteredBatches,
    required this.onDeleteBatch,
  });

  @override
  Widget build(BuildContext context) {
    if (filteredBatches.isEmpty) {
      // Hiển thị thông báo khác nhau tùy thuộc vào trạng thái lọc
      if (harvest.batches.isEmpty) {
        return const Center(child: Text('Chưa có mã nào. Hãy thêm mã mới!'));
      } else {
        return const Center(
          child: Text('Không tìm thấy mã nào phù hợp với bộ lọc.'),
        );
      }
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: filteredBatches.length,
      itemBuilder: (context, index) {
        final batch = filteredBatches[index];
        return BatchCard(
          harvestId: harvest.id,
          batch: batch,
          onDelete: () => onDeleteBatch(batch),
        );
      },
    );
  }
}

// Widget cho thẻ hiển thị thông tin một mã
class BatchCard extends StatelessWidget {
  final String harvestId;
  final Batch batch;
  final VoidCallback onDelete;

  const BatchCard({
    super.key,
    required this.harvestId,
    required this.batch,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,###.##");
    final completedUnits = batch.units.length;
    final totalUnits = Batch.maxUnits;

    return Card(
      clipBehavior: Clip.hardEdge,
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => BatchDetailScreen(
                    harvestId: harvestId,
                    batchId: batch.id,
                  ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      batch.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.delete, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('$completedUnits/$totalUnits bao'),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: completedUnits / totalUnits),
              const SizedBox(height: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tổng: ${formatter.format(batch.totalWeight)} kg',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (batch.isFull)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Hoàn thành',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
