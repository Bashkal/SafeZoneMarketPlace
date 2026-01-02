import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../widgets/image_from_string.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../models/product_model.dart';
import 'add_product_screen.dart';


class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  ProductStatus? _selectedStatusFilter;
  ProductCategory? _selectedCategoryFilter;
  ProductCondition? _selectedConditionFilter;

  bool get _hasFilters =>
      _selectedStatusFilter != null || _selectedCategoryFilter != null || _selectedConditionFilter != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductService>(context, listen: false).fetchProducts();
    });
  }

  List<Product> _filterProducts(List<Product> products) {
    var filtered = products;

    // Filter by status
    if (_selectedStatusFilter != null) {
      filtered = filtered
          .where((product) => product.status == _selectedStatusFilter)
          .toList();
    }

    // Filter by category
    if (_selectedCategoryFilter != null) {
      filtered = filtered
          .where((product) => product.category == _selectedCategoryFilter)
          .toList();
    }

    // Filter by condition
    if (_selectedConditionFilter != null) {
      filtered = filtered
          .where((product) => product.condition == _selectedConditionFilter)
          .toList();
    }

    return filtered;
  }

  void _openSearch() {
    final productService = Provider.of<ProductService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    showSearch(
      context: context,
      delegate: ProductSearchDelegate(
        products: productService.products,
        currentUserId: authService.currentUser?.uid ?? '',
        onFavorite: (productId) {
          if (authService.currentUser != null) {
            productService.toggleFavorite(productId, authService.currentUser!.uid);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductService>(context);
    final authService = Provider.of<AuthService>(context);
    final filteredProducts = _filterProducts(productService.products);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.storefront),
            SizedBox(width: 8),
            Text('Community Marketplace'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => productService.fetchProducts(),
            tooltip: 'Refresh products',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
            tooltip: 'Search products',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Filter buttons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                // Status Filter Button
                Expanded(
                  child: PopupMenuButton<ProductStatus?>(
                    tooltip: 'Filter by Status',
                    onSelected: (value) {
                      setState(() => _selectedStatusFilter = value);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedStatusFilter != null
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedStatusFilter != null
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_list,
                            size: 18,
                            color: _selectedStatusFilter != null
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _selectedStatusFilter != null
                                  ? _selectedStatusFilter!.displayName
                                  : 'Status',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _selectedStatusFilter != null
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: _selectedStatusFilter != null
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: null,
                        child: Text('All Status'),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: ProductStatus.available,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(ProductStatus.available.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ProductStatus.free,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(ProductStatus.free.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ProductStatus.reserved,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(ProductStatus.reserved.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ProductStatus.onsale,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(ProductStatus.onsale.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ProductStatus.soldOut,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(ProductStatus.soldOut.displayName),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Category Filter Button
                Expanded(
                  child: PopupMenuButton<ProductCategory?>(
                    tooltip: 'Filter by Category',
                    onSelected: (value) {
                      setState(() => _selectedCategoryFilter = value);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedCategoryFilter != null
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedCategoryFilter != null
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.category,
                            size: 18,
                            color: _selectedCategoryFilter != null
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _selectedCategoryFilter != null
                                  ? _selectedCategoryFilter!.displayName
                                  : 'Category',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _selectedCategoryFilter != null
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: _selectedCategoryFilter != null
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: ProductCategory.electronics,
                        child: Row(
                          children: [
                            const Icon(Icons.warning, size: 18),
                            const SizedBox(width: 8),
                            Text(ProductCategory.electronics.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ProductCategory.furniture,
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb, size: 18),
                            const SizedBox(width: 8),
                            Text(ProductCategory.furniture.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ProductCategory.clothing,
                        child: Row(
                          children: [
                            const Icon(Icons.checkroom, size: 18),
                            const SizedBox(width: 8),
                            Text(ProductCategory.clothing.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ProductCategory.books,
                        child: Row(
                          children: [
                            const Icon(Icons.book, size: 18),
                            const SizedBox(width: 8),
                            Text(ProductCategory.books.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ProductCategory.toys,
                        child: Row(
                          children: [
                            const Icon(Icons.toys, size: 18),
                            const SizedBox(width: 8),
                            Text(ProductCategory.toys.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ProductCategory.vehicles,
                        child: Row(
                          children: [
                            const Icon(Icons.directions_car, size: 18),
                            const SizedBox(width: 8),
                            Text(ProductCategory.vehicles.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ProductCategory.homegarden,
                        child: Row(
                          children: [
                            const Icon(Icons.grass, size: 18),
                            const SizedBox(width: 8),
                            Text(ProductCategory.homegarden.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ProductCategory.sports,
                        child: Row(
                          children: [
                            const Icon(Icons.sports_soccer, size: 18),
                            const SizedBox(width: 8),
                            Text(ProductCategory.sports.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ProductCategory.healthbeauty,
                        child: Row(
                          children: [
                            const Icon(Icons.health_and_safety, size: 18),
                            const SizedBox(width: 8),
                            Text(ProductCategory.healthbeauty.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ProductCategory.toolsandequipment,
                        child: Row(
                          children: [
                            const Icon(Icons.build, size: 18),
                            const SizedBox(width: 8),
                            Text(ProductCategory.toolsandequipment.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ProductCategory.other,
                        child: Row(
                          children: [
                            const Icon(Icons.category, size: 18),
                            const SizedBox(width: 8),
                            Text(ProductCategory.other.displayName),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                //Condition Filter
                Expanded(
                  child: PopupMenuButton<ProductCondition?>(
                    tooltip: 'Filter by Condition',
                    onSelected: (value) {
                      setState(() => _selectedConditionFilter = value);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedConditionFilter != null
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedConditionFilter != null
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.category,
                            size: 18,
                            color: _selectedConditionFilter != null
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _selectedConditionFilter != null
                                  ? _selectedConditionFilter!.displayName
                                  : 'Condition',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _selectedConditionFilter != null
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: _selectedConditionFilter != null
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: null,
                        child: Text('All Conditions'),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: ProductCondition.newCondition,
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, size: 18),
                            const SizedBox(width: 8),
                            Text(ProductCondition.newCondition.displayName),
                          ],
                        ),
                      ),
                       PopupMenuItem(
                        value: ProductCondition.likeNew,
                        child: Row(
                          children: [
                            const Icon(Icons.auto_fix_high, size: 18),
                            const SizedBox(width: 8),
                            Text(ProductCondition.likeNew.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ProductCondition.good,
                        child: Row(
                          children: [
                            const Icon(Icons.thumb_up, size: 18),
                            const SizedBox(width: 8),
                            Text(ProductCondition.good.displayName),
                          ],
                        ),
                      ),
                     
                      PopupMenuItem(
                        value: ProductCondition.fair,
                        child: Row(
                          children: [
                            const Icon(Icons.thumbs_up_down, size: 18),
                            const SizedBox(width: 8),
                            Text(ProductCondition.fair.displayName),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: ProductCondition.poor,
                        child: Row(
                          children: [
                            const Icon(Icons.sentiment_dissatisfied, size: 18),
                            const SizedBox(width: 8),
                            Text(ProductCondition.poor.displayName),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Clear Filters Button
                if (_hasFilters) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedStatusFilter = null;
                        _selectedCategoryFilter = null;
                        _selectedConditionFilter = null;
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Clear'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Products list
          Expanded(
            child: productService.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                ? RefreshIndicator(
                    onRefresh: () => productService.fetchProducts(),
                    // Empty state
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to add a product!',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => productService.fetchProducts(),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return ProductCard(
                          product: product,
                          currentUserId: authService.currentUser?.uid ?? '',
                          onFavorite: () {
                            if (authService.currentUser != null) {
                              productService.toggleFavorite(
                                product.id!,
                                authService.currentUser!.uid,
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}

// Search Delegate for searching products
class ProductSearchDelegate extends SearchDelegate<Product?> {
  final List<Product> products;
  final String currentUserId;
  final Function(String) onFavorite;

  ProductSearchDelegate({
    required this.products,
    required this.currentUserId,
    required this.onFavorite,
  });

  @override
  String get searchFieldLabel => 'Search by title, category, status or location';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Search for products',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching by title, category, or location',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final searchQuery = query.toLowerCase();
    final results = products.where((product) {
      return product.title.toLowerCase().contains(searchQuery) ||
          product.description.toLowerCase().contains(searchQuery) ||
          product.category.displayName.toLowerCase().contains(searchQuery) ||
          product.locationAddress.toLowerCase().contains(searchQuery) ||
          product.userName.toLowerCase().contains(searchQuery);
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        return ProductCard(
          product: product,
          currentUserId: currentUserId,
          onFavorite: () => onFavorite(product.id!),
        );
      },
    );
  }
}

class ProductCard extends StatefulWidget {
  final Product product;
  final String currentUserId;
  final VoidCallback onFavorite;

  const ProductCard({
    super.key,
    required this.product,
    required this.currentUserId,
    required this.onFavorite,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late PageController _pageController;
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

  Color _getStatusColor(BuildContext context) {
    switch (widget.product.status) {
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

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final currentUserId = widget.currentUserId;
    final isFavorited = product.favoritedBy.contains(currentUserId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: product.id == null
            ? null
            : () => Navigator.of(context).pushNamed(
                  '/product',
                  arguments: product.id,
                ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info header
            ListTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundImage: product.userPhotoUrl != null && product.userPhotoUrl!.isNotEmpty
                    ? NetworkImage(product.userPhotoUrl!)
                    : null,
                child: product.userPhotoUrl == null || product.userPhotoUrl!.isEmpty
                    ? Text(
                        product.userName.isNotEmpty ? product.userName[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              title: Text(product.userName),
              subtitle: Text(timeago.format(product.createdAt)),
              trailing: Chip(
                label: Text(
                  product.status.displayName,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: _getStatusColor(context).withValues(alpha: 0.2),
                labelStyle: TextStyle(color: _getStatusColor(context)),
                padding: EdgeInsets.zero,
              ),
            ),
            // Images carousel
            if (product.photoUrls.isNotEmpty)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                          },
                        ),
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: product.photoUrls.length,
                          itemBuilder: (context, index) {
                            return ImageFromString(
                              src: product.photoUrls[index],
                              fit: BoxFit.contain,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  // Image counter badge
                  if (product.photoUrls.length > 1)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentPageIndex + 1}/${product.photoUrls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    product.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Price
                  Text(
                    '\$${product.price?.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Category
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          product.category.displayName,
                          style: const TextStyle(fontSize: 12),
                        ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    //Condition
                    Chip(
                      label: Text(
                        product.condition.displayName,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer,
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),


                // Description
                Text(
                  product.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                  maxLines: 3,
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isFavorited ? Icons.favorite : Icons.favorite_border,
                      ),
                      onPressed: widget.onFavorite,
                      color: isFavorited
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    Text('${product.favorites}'),
                    const SizedBox(width: 16),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Admin controls
                Consumer<AuthService>(
                  builder: (context, auth, _) {
                    final isAdmin = auth.currentAppUser?.role.isAdmin ?? false;
                    if (!isAdmin) return const SizedBox.shrink();
                    final productService = Provider.of<ProductService>(
                      context,
                      listen: false,
                    );
                    return PopupMenuButton<String>(
                      tooltip: 'Admin Controls',
                      icon: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shield,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Admin Controls',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddProductScreen(existingProduct: product),
                            ),
                          );
                        } else if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Product'),
                              content: const Text(
                                'Are you sure you want to delete this product?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await productService.deleteProduct(
                                product.id!,
                                product.userId,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Product deleted'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed: $e')),
                                );
                              }
                            }
                          }
                        }
                      },
                      
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Edit Product'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text(
                              'Delete Product',
                              style: TextStyle(color: Colors.red),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ]
        ),
      ),
    );
  }
}
