import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../models/product_model.dart';
import 'location_picker_screen.dart';
import '../widgets/image_from_string.dart';

class AddProductScreen extends StatefulWidget {
  final Product? existingProduct;

  const AddProductScreen({super.key, this.existingProduct});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  static const double _maxImageWidth = 1920;
  static const double _maxImageHeight = 1080;
  static const int _imageQuality = 85;
  static const int _maxTitleLength = 100;
  static const int _maxDescriptionLength = 500;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  ProductCategory _selectedCategory = ProductCategory.other;
  ProductStatus _selectedStatus = ProductStatus.available;
  ProductCondition _selectedCondition = ProductCondition.good;
  final List<File> _images = [];
  final List<Uint8List> _webImages = [];
  final List<String> _existingPhotoUrls = [];
  final List<String> _removedPhotoUrls = [];
  LatLng? _selectedLocation;
  String _locationAddress = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingProduct != null) {
      _loadExistingProduct();
    } else {
      _getCurrentLocation();
    }
  }

  void _loadExistingProduct() {
    final product = widget.existingProduct!;
    _titleController.text = product.title;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toString();
    _selectedCategory = product.category;
    _selectedStatus = product.status;
    _selectedCondition = product.condition;
    _selectedLocation = product.location;
    _locationAddress = product.locationAddress;
    _existingPhotoUrls.addAll(product.photoUrls);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      _selectedLocation = LatLng(position.latitude, position.longitude);

      // Get address from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _locationAddress = '${place.street}, ${place.locality}';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    // Only use file_picker on web, never instantiate ImagePicker on web
    if (kIsWeb) {
      try {
        final result = await FilePicker.platform.pickFiles(type: FileType.image);
        if (result != null && result.files.single.bytes != null) {
          setState(() {
            _webImages.add(result.files.single.bytes!);
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to pick image: $e')),
          );
        }
      }
      return;
    }
    // Only use image_picker on mobile/desktop
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: _maxImageWidth,
        maxHeight: _maxImageHeight,
        imageQuality: _imageQuality,
      );
      if (pickedFile != null) {
        setState(() {
          _images.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ImageSourceSheet(
        onCameraSelected: () {
          Navigator.pop(context);
          _pickImage(ImageSource.camera);
        },
        onGallerySelected: () {
          Navigator.pop(context);
          _pickImage(ImageSource.gallery);
        },
      ),
    );
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LocationPickerScreen(initialLocation: _selectedLocation),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result['location'] as LatLng;
        _locationAddress = result['address'] as String;
      });
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a location')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final productService = Provider.of<ProductService>(context, listen: false);

      final currentUser = authService.currentUser;
      if (currentUser == null) {
        throw Exception('Authentication required. Please log in again.');
      }

      final product = _createProduct(currentUser);
      final isUpdate = widget.existingProduct != null;

      if (isUpdate) {
        await productService.updateProduct(
          widget.existingProduct!.id!,
          product,
          _images.isNotEmpty ? _images : null,
          removedPhotoUrls: _removedPhotoUrls.isNotEmpty
              ? _removedPhotoUrls
              : null,
        );
      } else {
        await productService.createProduct(product, _images);
      }

      // Don't wait for user data refresh - do it in background
      authService.refreshUserData();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUpdate
                  ? 'Product updated successfully'
                  : 'Product submitted successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingProduct != null ? 'Edit Product' : 'Add Product',
        ),
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., Vintage Wooden Chair',
                prefixIcon: Icon(Icons.title),
              ),
              maxLength: _maxTitleLength,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                if (value.trim().length < 5) {
                  return 'Title must be at least 5 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Provide more details here...',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              maxLength: _maxDescriptionLength,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                if (value.trim().length < 10) {
                  return 'Description must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Price
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                hintText: 'Enter the price',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a price';
                }
                final price = double.tryParse(value.trim());
                if (price == null || price < 0) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // Status 

            DropdownButtonFormField<ProductStatus>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.info),
              ),
              items: ProductStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedStatus = value);
                }
              },
            ),
            const SizedBox(height: 24),
            // Condition
            DropdownButtonFormField<ProductCondition>(
              initialValue: _selectedCondition,
              decoration: const InputDecoration(
                labelText: 'Condition',
                prefixIcon: Icon(Icons.build_circle),
              ),
              items: ProductCondition.values.map((condition) {
                return DropdownMenuItem(
                  value: condition,
                  child: Text(condition.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCondition = value);
                }
              },
            ),
            const SizedBox(height: 24),

            // Category
            DropdownButtonFormField<ProductCategory>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
              ),
              items: ProductCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 24),

            // Photos Section
            Text('Add Photos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            // Existing photos (for edit mode) with delete option
            if (_existingPhotoUrls.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _existingPhotoUrls.length,
                  itemBuilder: (context, index) {
                    final url = _existingPhotoUrls[index];
                    return Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ImageFromString(
                              src: url,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _removedPhotoUrls.add(url);
                                _existingPhotoUrls.removeAt(index);
                              });
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(24, 24),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            // New photos
            if (_images.isNotEmpty || _webImages.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._images.asMap().entries.map((entry) {
                      final index = entry.key;
                      final file = entry.value;
                      return Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                file,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 12,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () {
                                setState(() => _images.removeAt(index));
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(24, 24),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    ..._webImages.asMap().entries.map((entry) {
                      final index = entry.key;
                      final bytes = entry.value;
                      return Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                bytes,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 12,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () {
                                setState(() => _webImages.removeAt(index));
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(24, 24),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: _showImageSourceDialog,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Upload Media'),
            ),
            const SizedBox(height: 24),

            // Location Section
            Text(
              'Pinpoint the Location',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: _pickLocation,
              icon: const Icon(Icons.location_on),
              label: Text(
                _locationAddress.isEmpty ? 'Select Location' : _locationAddress,
              ),
            ),

            if (_selectedLocation != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                  'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 32),

            // Submit Button
            FilledButton(
              onPressed: _isLoading ? null : _submitReport,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.existingProduct != null
                          ? 'Update Product'
                          : 'Submit Product',
                    ),
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }

  Product _createProduct(dynamic currentUser) {
    final existing = widget.existingProduct;
    return Product(
      id: existing?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      category: _selectedCategory,
      condition: _selectedCondition,
      photoUrls: _existingPhotoUrls,
      location: _selectedLocation!,
      locationAddress: _locationAddress,
      userId: currentUser.uid,
      userName: currentUser.displayName ?? 'Anonymous',
      userPhotoUrl: currentUser.photoURL,
      createdAt: existing?.createdAt ?? DateTime.now(),
      status: _selectedStatus,
    );
  }
}

class _ImageSourceSheet extends StatelessWidget {
  final VoidCallback onCameraSelected;
  final VoidCallback onGallerySelected;

  const _ImageSourceSheet({
    required this.onCameraSelected,
    required this.onGallerySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take Photo'),
            onTap: onCameraSelected,
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: onGallerySelected,
          ),
        ],
      ),
    );
  }
}
