import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../widgets/image_from_string.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../models/product_model.dart';
import 'add_product_screen.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  static const double _cardRadius = 12;
  static const double _cardPadding = 16;
  static const double _imageAspectRatio = 16 / 9;

  List<Product> _userProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProducts();
  }

  Future<void> _loadUserProducts() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final productService = Provider.of<ProductService>(context, listen: false);

    if (authService.currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final products = await productService.fetchUserProducts(
        authService.currentUser!.uid,
      );
      setState(() {
        _userProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load products: $e')));
      }
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted) return; // Added mounted guard
    if (confirmed == true) {
      try {
        final productService = Provider.of<ProductService>(
          context,
          listen: false,
        );
        final authService = Provider.of<AuthService>(context, listen: false);

        await productService.deleteProduct(
          product.id!,
          authService.currentUser!.uid,
        );

        await _loadUserProducts();

        // Refresh user data so profile product count stays in sync
        await authService.refreshUserData();

        if (mounted) { // Check if mounted before showing snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete product: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _editProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(existingProduct: product),
      ),
    ).then((_) => _loadUserProducts());
  }

  Widget _buildEmptyState(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadUserProducts,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No products yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Start by creating your first product!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

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
  Color getConditionColor(ProductCondition condition) {
    switch (condition) {
      case ProductCondition.newCondition:
        return Colors.green;
      case ProductCondition.likeNew:
        return Colors.lightGreen;
      case ProductCondition.good:
        return Colors.yellow;
      case ProductCondition.fair:
        return Colors.orange;
      case ProductCondition.poor:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Products')),
      body: authService.currentUser == null
          ? const Center(child: Text('Please sign in to view your products'))
          : _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProducts.isEmpty
          ? _buildEmptyState(context)
          : RefreshIndicator(
              onRefresh: _loadUserProducts,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _userProducts.length,
                    itemBuilder: (context, index) {
                      final product = _userProducts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_cardRadius),
                        ),
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Images carousel
                        if (product.photoUrls.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(_cardRadius),
                            ),
                            child: _ProductImageCarousel(
                              photoUrls: product.photoUrls,
                              aspectRatio: _imageAspectRatio,
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.all(_cardPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date
                              Text(
                                timeago.format(product.createdAt),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 8),

                              // Title
                              Text(
                                product.title,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              // Status
                              Chip(
                                label: Text(
                                  product.status.displayName,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: _getStatusColor(
                                  product.status,
                                ).withValues(alpha: 0.2),
                                labelStyle: TextStyle(
                                  color: _getStatusColor(product.status),
                                ),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(height: 8),
                              // Condition
                              Chip(
                                label: Text(
                                  product.condition.displayName,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: getConditionColor(
                                  product.condition,
                                ).withValues(alpha: 0.2),
                                labelStyle: TextStyle(
                                  color: getConditionColor(product.condition),
                                ),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(height: 8),
                              //Category
                              Chip(
                                label: Text(
                                  product.category.displayName,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.2),
                                labelStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(height: 16),

                              // Description
                              Text(
                                product.description,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),

                              // Actions
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _editProduct(product),
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () => _deleteProduct(product),
                                      icon: const Icon(Icons.delete),
                                      label: const Text('Delete'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),          ),
        ),    );
  }
}

class _ProductImageCarousel extends StatefulWidget {
  final List<String> photoUrls;
  final double aspectRatio;

  const _ProductImageCarousel({
    required this.photoUrls,
    required this.aspectRatio,
  });

  @override
  State<_ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<_ProductImageCarousel> {
  late final PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    setState(() {
      _currentPageIndex = _pageController.page?.round() ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
            ),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.photoUrls.length,
              itemBuilder: (context, index) {
                return ImageFromString(
                  src: widget.photoUrls[index],
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
        ),
        if (widget.photoUrls.length > 1)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentPageIndex + 1}/${widget.photoUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
