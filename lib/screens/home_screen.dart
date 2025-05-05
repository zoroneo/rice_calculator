import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/harvest_provider.dart';
import '../models/harvest.dart';
import 'create_harvest_screen.dart';
import 'harvest_detail_screen.dart';
import '../widgets/app_message.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.endOfFrame.whenComplete(() {
      if (!_isInit) {
        _initializeData();
        _isInit = true;
      }
    });
  }

  Future<void> _initializeData() async {
    final provider = Provider.of<HarvestProvider>(context, listen: false);
    await provider.initialize();
  }

  // Refresh data when returning to this screen
  void _refreshData() {
    final provider = Provider.of<HarvestProvider>(context, listen: false);
    provider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiện Tính Cân Lúa'),
        centerTitle: true,
      ),
      body: Consumer<HarvestProvider>(
        builder: (ctx, provider, child) {
          if (provider.isLoading) {
            return const AppMessage(
              isLoading: true,
              message: 'Đang tải dữ liệu...',
            );
          }

          if (provider.hasError) {
            return AppMessage(
              isError: true,
              message: provider.errorMessage,
              onRetry: () => provider.initialize(),
            );
          }

          if (provider.harvests.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có vụ mùa nào. Hãy thêm vụ mới!',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return HarvestListView(
            harvests: provider.harvests,
            onHarvestTap:
                (harvestId) => _navigateToHarvestDetail(context, harvestId),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_add_harvest',
        onPressed: () => _navigateToCreateHarvest(context),
        tooltip: 'Thêm vụ mới',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToCreateHarvest(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateHarvestScreen()),
    );

    // Refresh data when returning from create screen if a harvest was created
    if (result == true) {
      _refreshData();
    }
  }

  void _navigateToHarvestDetail(BuildContext context, String harvestId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HarvestDetailScreen(harvestId: harvestId),
      ),
    );

    // Refresh data when returning from detail screen
    if (result == true) {
      _refreshData();
    }
  }
}

// Widget riêng biệt cho danh sách vụ mùa
class HarvestListView extends StatelessWidget {
  final List<Harvest> harvests;
  final Function(String harvestId) onHarvestTap;

  const HarvestListView({
    super.key,
    required this.harvests,
    required this.onHarvestTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: harvests.length,
      itemBuilder: (ctx, index) {
        final harvest = harvests[index];
        return HarvestCard(
          harvest: harvest,
          onTap: () => onHarvestTap(harvest.id),
        );
      },
    );
  }
}

// Widget riêng biệt cho thẻ hiển thị thông tin một vụ mùa
class HarvestCard extends StatelessWidget {
  final Harvest harvest;
  final VoidCallback onTap;

  const HarvestCard({super.key, required this.harvest, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,###.##");
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with name and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      harvest.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
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

              // Dates section
              Text(
                'Ngày tạo: ${dateFormatter.format(harvest.createdAt)}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              if (harvest.completedAt != null)
                Text(
                  'Hoàn thành: ${dateFormatter.format(harvest.completedAt!)}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),

              const Divider(height: 16),

              // First row: Count information
              Row(
                children: [
                  Expanded(
                    child: HarvestInfoItem(
                      label: 'Số mã',
                      value: '${harvest.batches.length}',
                      icon: Icons.view_module,
                    ),
                  ),
                  Expanded(
                    child: HarvestInfoItem(
                      label: 'Số bao',
                      value: '${harvest.totalBags}',
                      icon: Icons.inventory_2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Second row: Weight information
              Row(
                children: [
                  Expanded(
                    child: HarvestInfoItem(
                      label: 'Tổng cân',
                      value: '${formatter.format(harvest.totalWeight)} kg',
                      icon: Icons.scale,
                    ),
                  ),
                  Expanded(
                    child: HarvestInfoItem(
                      label: 'Tịnh',
                      value: '${formatter.format(harvest.netWeight)} kg',
                      icon: Icons.line_weight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Third row: Price information
              Row(
                children: [
                  Expanded(
                    child: HarvestInfoItem(
                      label: 'Đơn giá',
                      value: '${formatter.format(harvest.unitPrice)}₫/kg',
                      icon: Icons.attach_money,
                    ),
                  ),
                  Expanded(
                    child: HarvestInfoItem(
                      label: 'Trừ bì',
                      value: '${harvest.bagDeduction} kg/bao',
                      icon: Icons.remove_circle_outline,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Payment information
              PaymentSummary(totalPayment: harvest.totalPayment),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget riêng biệt cho từng mục thông tin
class HarvestInfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const HarvestInfoItem({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Widget riêng biệt cho phần tổng thanh toán
class PaymentSummary extends StatelessWidget {
  final double totalPayment;

  const PaymentSummary({super.key, required this.totalPayment});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,###.##");

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text('Thành tiền:', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${formatter.format(totalPayment)}₫',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
