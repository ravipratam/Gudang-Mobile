import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gudang_mobile/core/constants/app_colors.dart';
import 'package:gudang_mobile/core/utils/formatters.dart';
import 'package:gudang_mobile/ui/core/custom_button.dart';
import 'package:gudang_mobile/ui/core/custom_text_field.dart';
import 'package:gudang_mobile/data/models/product_model.dart';
import '../view_models/product_view_model.dart';
import '../../auth/view_models/auth_view_model.dart';

class ProductFormView extends StatefulWidget {
  final ProductModel? productToEdit;

  const ProductFormView({super.key, this.productToEdit});

  @override
  State<ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends State<ProductFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _skuController;
  late final TextEditingController _nameController;
  late final TextEditingController _stockController;
  late final TextEditingController _minStockController;
  late final TextEditingController _locationController;

  int? _selectedCategoryId;

  bool get isEditing => widget.productToEdit != null;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _skuController = TextEditingController(text: p?.sku ?? '');
    _nameController = TextEditingController(text: p?.name ?? '');
    _stockController = TextEditingController(text: p?.stock.toString() ?? '0');
    _minStockController = TextEditingController(text: p?.minStock.toString() ?? '5');
    _locationController = TextEditingController(text: p?.location ?? '');
    _selectedCategoryId = p?.categoryId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ProductViewModel>();
      if (vm.categories.isEmpty) {
        vm.fetchCategories();
      }
    });
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _generateNewSku() {
    final catVm = context.read<ProductViewModel>();
    String prefix = 'PRD';
    if (_selectedCategoryId != null) {
      final cat = catVm.categories.where((c) => c.id == _selectedCategoryId).firstOrNull;
      if (cat != null) {
        prefix = cat.name;
      }
    }
    setState(() {
      _skuController.text = Formatters.generateSku(prefix);
    });
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    AuthViewModel? authVm;
    try {
      authVm = context.read<AuthViewModel>();
    } catch (_) {
      authVm = null;
    }
    if (authVm != null && !authVm.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? 'Hanya akun Admin yang diizinkan mengubah data barang.'
              : 'Hanya akun Admin yang diizinkan menambah barang baru.'),
          backgroundColor: AppColors.critical,
        ),
      );
      return;
    }

    final productVm = context.read<ProductViewModel>();
    final int stock = int.tryParse(_stockController.text.trim()) ?? 0;
    final int minStock = int.tryParse(_minStockController.text.trim()) ?? 5;

    final product = ProductModel(
      id: widget.productToEdit?.id ?? '',
      sku: _skuController.text.trim().toUpperCase(),
      name: _nameController.text.trim(),
      categoryId: _selectedCategoryId,
      stock: stock,
      minStock: minStock,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      createdAt: widget.productToEdit?.createdAt ?? DateTime.now(),
    );

    final bool success;
    if (isEditing) {
      success = await productVm.updateProduct(product);
    } else {
      success = await productVm.addProduct(product);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Data barang berhasil diperbarui.'
                : 'Barang baru berhasil ditambahkan.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, product);
    } else if (mounted && productVm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(productVm.errorMessage!),
          backgroundColor: AppColors.critical,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productVm = context.watch<ProductViewModel>();
    AuthViewModel? authVm;
    try {
      authVm = context.watch<AuthViewModel>();
    } catch (_) {
      authVm = null;
    }

    final isStaffRestricted = authVm != null && !authVm.isAdmin;
    if (isStaffRestricted) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Akses Dibatasi'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_person_outlined, size: 64, color: AppColors.critical),
                const SizedBox(height: 16),
                Text(
                  isEditing ? 'Fitur Ubah Data Barang Dibatasi' : 'Fitur Tambah Barang Dibatasi',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isEditing
                      ? 'Hanya pengguna dengan akun Admin yang memiliki izin untuk mengubah data barang di gudang.'
                      : 'Hanya pengguna dengan akun Admin yang memiliki izin untuk menambah barang baru ke gudang.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Ubah Data Barang' : 'Tambah Barang Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // SKU Input with Auto-Generate
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Kode SKU / Barcode',
                      hint: 'ELK-12345',
                      controller: _skuController,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'SKU wajib diisi';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        minimumSize: const Size(0, 40),
                      ),
                      onPressed: _generateNewSku,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Auto', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Product Name
              CustomTextField(
                label: 'Nama Barang',
                hint: 'Contoh: Hand Pallet Truck 3 Ton',
                controller: _nameController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Nama barang wajib diisi';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kategori Barang',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: productVm.categories.any((cat) => cat.id == _selectedCategoryId)
                        ? _selectedCategoryId
                        : null,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    hint: const Text('Pilih kategori barang'),
                    items: productVm.categories.map((cat) {
                      return DropdownMenuItem<int>(
                        value: cat.id,
                        child: Text(cat.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategoryId = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stock & Min Stock Inputs
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Jumlah Stok Awal',
                      hint: '0',
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                        final numVal = int.tryParse(v.trim());
                        if (numVal == null || numVal < 0) return 'Harus angka >= 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Batas Stok Minimum',
                      hint: '5',
                      controller: _minStockController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                        final numVal = int.tryParse(v.trim());
                        if (numVal == null || numVal < 0) return 'Harus angka >= 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location / Rack Position
              CustomTextField(
                label: 'Lokasi Rak / Zona Gudang',
                hint: 'Contoh: Rak A-03, Zona Pallet C',
                controller: _locationController,
                prefixIcon: const Icon(Icons.place_outlined, size: 20),
              ),
              const SizedBox(height: 28),

              // Submit Button
              CustomButton(
                text: isEditing ? 'Simpan Perubahan' : 'Tambah ke Gudang',
                icon: Icons.check,
                isLoading: productVm.isLoading,
                onPressed: _onSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
