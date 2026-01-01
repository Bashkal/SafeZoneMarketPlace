import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/product_model.dart';
import '../utils/image_utils.dart';

class ProductService extends ChangeNotifier {
  static const String _productsPath = 'products';
  static const String _usersPath = 'users';
  static const String _productsSubmittedKey = 'productsSubmitted';

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Product> _products = [];
  List<Product> get products => _products;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Fetch all products
  Future<void> fetchProducts() async {
    try {
      _setLoading(true);

      final snap = await _database.ref().child(_productsPath).get();

      if (!snap.exists || snap.value == null) {
        _products = [];
      } else {
        final data = snap.value as Map<dynamic, dynamic>;
        final list = <Product>[];
        data.forEach((key, value) {
          try {
            final map = Map<String, dynamic>.from(value as Map);
            list.add(Product.fromMap(key.toString(), map));
          } catch (e) {
            if (kDebugMode) print('Error parsing product entry: $e');
          }
        });

        // Sort by createdAt descending
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _products = list;
      }

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      if (kDebugMode) {
        print('Error fetching products: $e');
      }
      rethrow;
    }
  }

  // Fetch user's products
  Future<List<Product>> fetchUserProducts(String userId) async {
    try {
      final snap = await _database.ref().child(_productsPath).get();
      final products = <Product>[];
      if (!snap.exists || snap.value == null) return products;

      final data = snap.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        try {
          final map = Map<String, dynamic>.from(value as Map);
          if (map['userId'] == userId) {
            products.add(Product.fromMap(key.toString(), map));
          }
        } catch (e) {
          if (kDebugMode) print('Error parsing product entry: $e');
        }
      });

      // Sort by createdAt manually
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return products;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching user products: $e');
      }
      rethrow;
    }
  }

  // Compress images and return base64 strings to store in Realtime Database
  Future<List<String>> uploadImagesAsBase64(
    List<dynamic> images, {
    int targetWidth = 800,
    int quality = 70,
    int maxImages = 3,
  }) async {
    List<String> imageBase64 = [];

    final limit = images.length < maxImages ? images.length : maxImages;

    for (int i = 0; i < limit; i++) {
      try {
        String base64;
        final image = images[i];
        
        if (image is File) {
          // Handle mobile/desktop File objects
          base64 = await ImageUtils.compressFileToBase64(
            image,
            targetWidth: targetWidth,
            quality: quality,
          );
        } else if (image is Uint8List) {
          // Handle web Uint8List bytes
          base64 = await ImageUtils.compressBytesToBase64(
            image,
            targetWidth: targetWidth,
            quality: quality,
          );
        } else {
          if (kDebugMode) {
            print('Unknown image type: ${image.runtimeType}');
          }
          continue;
        }
        
        imageBase64.add(base64);
      } catch (e) {
        if (kDebugMode) {
          print('Error compressing/uploading image as base64: $e');
        }
      }
    }

    return imageBase64;
  }

  // Create a new product
  Future<void> createProduct(Product product, List<dynamic> images) async {
    try {
      // Create a new product node to get a key
      final ref = _database.ref().child(_productsPath).push();
      // Prepare base map and set it (photoUrls may be empty for now)
      final map = product.toMap();
      await ref.set(map);

      // Update user's product count first (before heavy image processing)
      await _updateUserProductCount(product.userId, 1);
      // Upload images in background if any (don't block the UI return)
      if (images.isNotEmpty) {
        uploadImagesAsBase64(images).then((imageBase64) {
          if (imageBase64.isNotEmpty) {
            ref.update({'photoUrls': imageBase64});
          }
        }).catchError((e) {
          if (kDebugMode) {
            print('Error uploading images in background: $e');
          }
        });
      }

      // Refresh products in background (don't block the UI)
      fetchProducts();
    } catch (e) {
      if (kDebugMode) {
        print('Error creating product: $e');
      }
      rethrow;
    }
  }

  // Update a product
  Future<void> updateProduct(
    String productId,
    Product product,
    List<dynamic>? newImages, {
    List<String>? removedPhotoUrls,
  }) async {
    try {
      final ref = _database.ref().child(_productsPath).child(productId);

      Map<String, Object?> updateData = {
        'title': product.title,
        'description': product.description,
        'category': product.category.name,
        'price': product.price,
        'condition': product.condition.name,
        'status': product.status.name,
        'locationAddress': product.locationAddress,
        'latitude': product.location.latitude,
        'longitude': product.location.longitude,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Read existing photoUrls (we may need to remove items or append new uploads)
      final snap = await ref.get();
      List<dynamic> existing = [];
      if (snap.exists && snap.value is Map) {
        final map = Map<String, dynamic>.from(snap.value as Map);
        existing = List<dynamic>.from(map['photoUrls'] ?? []);
      }

      // Remove any requested photo URLs
      if (removedPhotoUrls != null && removedPhotoUrls.isNotEmpty) {
        existing.removeWhere((e) => removedPhotoUrls.contains(e));
      }

      // Upload new images (as base64) and append
      if (newImages != null && newImages.isNotEmpty) {
        final imageBase64 = await uploadImagesAsBase64(newImages);
        if (imageBase64.isNotEmpty) {
          existing = [...existing, ...imageBase64];
        }
      }

      updateData['photoUrls'] = existing;

      await ref.update(updateData);
      await fetchProducts();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating product: $e');
      }
      rethrow;
    }
  }

  // Delete a report
  Future<void> deleteProduct(String productId, String userId) async {
    try {
      final ref = _database.ref().child(_productsPath).child(productId);
      await ref.remove();

      await _updateUserProductCount(userId, -1);

      await fetchProducts();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting product: $e');
      }
      rethrow;
    }
  }

  // Toggle favorite on a product
  Future<void> toggleFavorite(String productId, String userId) async {
    try {
      final ref = _database.ref().child(_productsPath).child(productId);
      final snap = await ref.get();
      if (!snap.exists) return;

      final data = snap.value as Map<dynamic, dynamic>;
      final favoritedBy = List<String>.from(data['favoritedBy'] ?? []);
      int favorites = data['favorites'] is int
          ? data['favorites'] as int
          : (int.tryParse('${data['favorites']}') ?? 0);

      if (favoritedBy.contains(userId)) {
        // Unfavorite
        favoritedBy.remove(userId);
        favorites = favorites - 1 < 0 ? 0 : favorites - 1;
      } else {
        favoritedBy.add(userId);
        favorites = favorites + 1;
      }

      await ref.update({'favorites': favorites, 'favoritedBy': favoritedBy});

      await fetchProducts();
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling favorite: $e');
      }
      rethrow;
    }
  }

  // Update product status (admin function)
  Future<void> updateProductStatus(String productId, ProductStatus status) async {
    try {
      final ref = _database.ref().child(_productsPath).child(productId);
      await ref.update({
        'status': status.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await fetchProducts();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating product status: $e');
      }
      rethrow;
    }
  }

  Future<void> _updateUserProductCount(String userId, int delta) async {
    // RTDB update
    try {
      final userRef = _database.ref().child(_usersPath).child(userId);
      final snap = await userRef.get();
      int current = 0;
      if (snap.exists && snap.value is Map) {
        current = _parseProductsCount(
          Map<String, dynamic>.from(snap.value as Map),
        );
      }
      final next = (current + delta).clamp(0, 1 << 31);
      await userRef.set({_productsSubmittedKey: next});

      // Mirror to Firestore
      await _firestore.collection(_usersPath).doc(userId).set({
        _productsSubmittedKey: next,
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print('Warning: failed to update product count: $e');
      }
    }
  }

  int _parseProductsCount(Map<String, dynamic> data) {
    final value = data[_productsSubmittedKey];
    if (value is int) return value;
    if (value != null) return int.tryParse('$value') ?? 0;
    return 0;
  }
}
