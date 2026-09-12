import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/product_service.dart';
import '../../utils/app_toast.dart';

class ProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _productNameController;
  late TextEditingController _brandNameController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _minimumStockController;

  bool _isActive = true;
  double _selectedBagSize = 25.0;
  bool _isLoading = false;

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _removeImage = false;

  final List<double> _bagSizes = [5.0, 10.0, 25.0, 50.0, 75.0, 100.0];

  final Color primaryGreen = const Color(0xFF0F2C1A); // Darker green
  final Color secondaryGreen = const Color(0xFF163E26); // Lighter green
  final Color accentGold = const Color(0xFFD4AF37);
  Color get textPrimary => Theme.of(context).colorScheme.onSurface;

  final Color surfaceColor = const Color(0xFF163E26)
      .withOpacity(0.5); // Card background

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController(
      text: widget.product?['name'] ?? '',
    );
    _brandNameController = TextEditingController(
      text: widget.product?['brand'] ?? '',
    );
    _purchasePriceController = TextEditingController(
      text: widget.product != null
          ? widget.product!['purchasePrice'].toString()
          : '',
    );
    _sellingPriceController = TextEditingController(
      text: widget.product != null
          ? widget.product!['sellingPrice'].toString()
          : '',
    );
    _minimumStockController = TextEditingController(
      text: widget.product != null
          ? widget.product!['minimumStockLevel'].toString()
          : '',
    );

    if (widget.product != null) {
      _isActive = widget.product!['isActive'] ?? true;
      _selectedBagSize = widget.product!['bagSize'] ?? 25.0;
      if (!_bagSizes.contains(_selectedBagSize)) {
        _bagSizes.add(_selectedBagSize);
        _bagSizes.sort();
      }
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _brandNameController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _minimumStockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = pickedFile.name;
        _removeImage = false;
      });
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
      _removeImage = true;
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final productData = {
      'productName': _productNameController.text.trim(),
      'brandName': _brandNameController.text.trim(),
      'bagSize': _selectedBagSize,
      'purchasePrice': double.tryParse(_purchasePriceController.text) ?? 0.0,
      'sellingPrice': double.tryParse(_sellingPriceController.text) ?? 0.0,
      'minimumStockLevel': double.tryParse(_minimumStockController.text) ?? 0.0,
      'isActive': _isActive,
    };

    try {
      if (_isEditing) {
        await ProductService.updateProduct(
          widget.product!['id'], 
          productData,
          imageBytes: _selectedImageBytes,
          imageName: _selectedImageName,
          removeImage: _removeImage,
        );
      } else {
        await ProductService.createProduct(
          productData,
          imageBytes: _selectedImageBytes,
          imageName: _selectedImageName,
        );
      }

      if (mounted) {
        AppToast.showSuccess(
          context,
          widget.product != null
              ? 'Product updated successfully!'
              : 'Product created successfully!',
        );
        Navigator.pop(context, true); // Return true to refresh list
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving product: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
        : Theme.of(context).colorScheme.surface;
    final cardBorderColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1);
    final accentColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Edit Product' : 'Add Product',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              _isEditing
                  ? 'Update product information'
                  : 'Create a new rice product',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accentColor, width: 2),
                image: const DecorationImage(
                  image: AssetImage('assets/images/sack_of_rice_icon.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: isDark ? null : Theme.of(context).scaffoldBackgroundColor,
        decoration: isDark ? BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 1.2,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).primaryColor,
              Colors.black,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ) : null,
        child: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildImageUploadCard(),
                      const SizedBox(height: 16),
                      _buildProductInfoSection(),
                      const SizedBox(height: 16),
                      if (_isEditing)
                        _buildStockLockCard()
                      else
                        _buildInitialStockInfoCard(),
                      const SizedBox(height: 16),
                      _buildStatusCard(),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.primary,
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _saveProduct,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isEditing ? 'Update Product' : 'Save Product',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildImageUploadCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget imageProvider;
    if (_selectedImageBytes != null) {
      imageProvider = Image.memory(_selectedImageBytes!, fit: BoxFit.cover);
    } else if (widget.product?['imageUrl'] != null && !_removeImage) {
      imageProvider = Image.network(
        'http://localhost:5246${widget.product!['imageUrl']}',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 40),
      );
    } else {
      imageProvider = Icon(
        Icons.add_photo_alternate,
        size: 40,
        color: Theme.of(context).colorScheme.primary,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              clipBehavior: Clip.hardEdge,
              child: imageProvider,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Image',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Upload a clear image of the product (Max 5MB)',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload_file, size: 16),
                      label: const Text('Browse'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    if (_selectedImageBytes != null ||
                        (widget.product?['imageUrl'] != null && !_removeImage)) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _removeSelectedImage,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                        child: const Text('Remove'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfoSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.grass,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Product Information',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Product Name',
            controller: _productNameController,
            hint: 'Enter rice variety',
            required: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Brand Name',
            controller: _brandNameController,
            hint: 'Enter brand name',
            required: true,
          ),
          const SizedBox(height: 16),
          Text(
            'Bag Size *',
            style: TextStyle(color: textPrimary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<double>(
            initialValue: _selectedBagSize,
            decoration: _inputDecoration('Select bag size'),
            dropdownColor: isDark
              ? Theme.of(context).primaryColor
              : Theme.of(context).colorScheme.surface,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: Theme.of(context).colorScheme.primary,
            ),
            items: _bagSizes.map((size) {
              return DropdownMenuItem<double>(
                value: size,
                child: Text(
                  '${size.toStringAsFixed(0)} kg',
                  style: TextStyle(color: textPrimary),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedBagSize = value);
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Purchase Price',
                  controller: _purchasePriceController,
                  hint: '₹ 0.00',
                  keyboardType: TextInputType.number,
                  required: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  label: 'Selling Price',
                  controller: _sellingPriceController,
                  hint: '₹ 0.00',
                  keyboardType: TextInputType.number,
                  required: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Minimum Stock Level',
            controller: _minimumStockController,
            hint: 'Enter minimum bags',
            keyboardType: TextInputType.number,
            required: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInitialStockInfoCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
            ),
            child: Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Initial Stock',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add stock through Stock Inward after saving',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockLockCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accentGold.withOpacity(0.5)),
            ),
            child: Icon(
              Icons.lock_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Stock',
                  style: TextStyle(color: textPrimary, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.product?['currentStock']?.toStringAsFixed(0) ?? '0'} bags',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stock cannot be edited directly\nUpdated through Stock Inward and Sales',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Status',
            style: TextStyle(color: textPrimary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: _isActive ? Theme.of(context).colorScheme.primary : Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _isActive
                        ? 'Product is available for sales'
                        : 'Product is hidden from sales',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
                activeThumbColor: Theme.of(context).colorScheme.primary,
                activeTrackColor: Colors.green.withValues(alpha: 0.5),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(color: textPrimary, fontSize: 12),
            children: [
              if (required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.redAccent),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: textPrimary),
          decoration: _inputDecoration(hint),
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) return 'Required';
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
      ),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
