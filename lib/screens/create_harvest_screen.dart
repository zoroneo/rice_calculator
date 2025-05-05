import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/harvest_provider.dart';
import '../widgets/app_message.dart';

class CreateHarvestScreen extends StatefulWidget {
  const CreateHarvestScreen({super.key});

  @override
  State<CreateHarvestScreen> createState() => _CreateHarvestScreenState();
}

class _CreateHarvestScreenState extends State<CreateHarvestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _deductionController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Set default values
    _priceController.text = '8000'; // Default price 8000 VND/kg
    _deductionController.text = '1.5'; // Default deduction 1.5kg per bag
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _deductionController.dispose();
    super.dispose();
  }

  Future<void> _saveHarvest() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final name = _nameController.text.trim();
        final price = double.parse(_priceController.text.trim());
        final deduction = double.parse(_deductionController.text.trim());

        await Provider.of<HarvestProvider>(
          context,
          listen: false,
        ).addHarvest(name, price, deduction);

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        // Show error message
        setState(() {
          _errorMessage = 'Không thể tạo vụ mùa: ${e.toString()}';
        });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_errorMessage!)));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo Vụ Mùa Mới')),
      body:
          _isLoading
              ? const AppMessage(isLoading: true, message: 'Đang tạo vụ mùa...')
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên Vụ Mùa',
                          hintText: 'Vụ Đông Xuân 2025',
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.sentences,
                        autofocus: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên vụ mùa';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Giá mỗi kg (₫)',
                          hintText: '8000',
                          border: OutlineInputBorder(),
                          prefixText: '₫ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập giá';
                          }
                          final price = double.tryParse(value);
                          if (price == null) {
                            return 'Vui lòng nhập số hợp lệ';
                          }
                          if (price <= 0) {
                            return 'Giá phải lớn hơn 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _deductionController,
                        decoration: const InputDecoration(
                          labelText: 'Trừ Bì Mỗi Bao (kg)',
                          hintText: '1.5',
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
                            return 'Vui lòng nhập giá trị trừ bì';
                          }
                          final deduction = double.tryParse(value);
                          if (deduction == null) {
                            return 'Vui lòng nhập số hợp lệ';
                          }
                          if (deduction < 0) {
                            return 'Giá trị trừ bì không thể âm';
                          }
                          return null;
                        },
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _saveHarvest,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Tạo Vụ Mùa',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
