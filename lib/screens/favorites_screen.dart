import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final productService = Provider.of<ProductService>(context);
    final currentUserId = authService.currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favorites')),
        body: const Center(
          child: Text('Please sign in to view your favorites'),
        ),
      );
    }

    final favoriteProducts = productService.products
        .where((p) => p.favoritedBy.contains(currentUserId))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favoriteProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start adding products to your favorites!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => productService.fetchProducts(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: favoriteProducts.length,
                    itemBuilder: (context, index) {
                      final product = favoriteProducts[index];
                      return _FavoriteProductCard(
                        product: product,
                        currentUserId: currentUserId,
                      );
                    },
                  ),
                ),
              ),
            ),
    );
  }
}

class _FavoriteProductCard extends StatelessWidget {
  final Product product;
  final String currentUserId;

  const _FavoriteProductCard({
    required this.product,
    required this.currentUserId,
  });

  Color _getStatusColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.available:
        return Colors.green;
      case ProductStatus.soldOut:
        return Colors.grey;
      case ProductStatus.free:
        return Colors.blue;
      case ProductStatus.reserved:
        return Colors.orange;
      case ProductStatus.onsale:
        return Colors.red;
    }
  }

  IconData _getCategoryIcon(ProductCategory category) {
    switch (category) {
      case ProductCategory.electronics:
        return Icons.electrical_services;
      case ProductCategory.furniture:
        return Icons.chair;
      case ProductCategory.clothing:
        return Icons.checkroom;
      case ProductCategory.books:
        return Icons.book;
      case ProductCategory.toys:
        return Icons.toys;
      case ProductCategory.vehicles:
        return Icons.directions_car;
      case ProductCategory.homegarden:
        return Icons.yard;
      case ProductCategory.sports:
        return Icons.sports_soccer;
      case ProductCategory.healthbeauty:
        return Icons.spa;
      case ProductCategory.toolsandequipment:
        return Icons.build;
      case ProductCategory.other:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductService>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: product.id == null
            ? null
            : () => Navigator.of(context).pushNamed(
                  '/product',
                  arguments: product.id,
                ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: user info + time
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: product.userPhotoUrl != null &&
                            product.userPhotoUrl!.isNotEmpty
                        ? NetworkImage(product.userPhotoUrl!)
                        : null,
                    child: product.userPhotoUrl == null ||
                            product.userPhotoUrl!.isEmpty
                        ? Text(
                            product.userName.isNotEmpty
                                ? product.userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 16),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.userName,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          timeago.format(product.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () async {
                      try {
                        await productService.toggleFavorite(
                          product.id!,
                          currentUserId,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to remove: $e')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                product.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              // Price
              Text(
                product.price != null && product.price! > 0
                    ? '\$${product.price!.toStringAsFixed(2)}'
                    : 'Free',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),

              // Category and Status chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: Icon(
                      _getCategoryIcon(product.category),
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    label: Text(product.category.displayName),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label: Text(product.status.displayName),
                    backgroundColor:
                        _getStatusColor(product.status).withValues(alpha: 0.2),
                    labelStyle: TextStyle(color: _getStatusColor(product.status)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                product.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Location
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      product.locationAddress,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
