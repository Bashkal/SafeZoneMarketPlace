import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import '../widgets/image_from_string.dart';
import '../services/auth_service.dart';


class ProductDetailScreen extends StatelessWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});
  
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
      case ProductCategory.other:
        return Icons.category;
      case ProductCategory.sports:
        return Icons.sports_soccer;
      case ProductCategory.healthbeauty:
        return Icons.spa;
      case ProductCategory.toolsandequipment:
        return Icons.build;    
    }
  }

  Color _getStatusColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.available:
        return Colors.green;
      case ProductStatus.free:
        return Colors.blue;
      case ProductStatus.soldOut:
        return Colors.grey;
      case ProductStatus.reserved:
        return Colors.orange;
      case ProductStatus.onsale:
        return Colors.red;
    }
  }
  Color _getConditionColor(ProductCondition condition) {
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
    final ref = FirebaseDatabase.instance.ref('products/$productId');

    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.snapshot.value;
          if (data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Product not found (ID: $productId)', textAlign: TextAlign.center),
              ),
            );
          }

          if (data is Map) {
            final map = Map<String, dynamic>.from(data);
            final product = Product.fromMap(productId, map);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.photoUrls.isNotEmpty)
                        _DetailImageCarousel(photoUrls: product.photoUrls),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: user avatar + name + time
                            Row(
                              children: [
                                CircleAvatar(
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
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.userName.isNotEmpty ? product.userName : 'Anonymous',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Text(
                                        timeago.format(product.createdAt),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Title
                            Row(
                              children: [
                                Text(
                                  product.title,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                
                                const Spacer(),
                                // Price
                                Text(
                                  product.price != null && product.price! > 0 ? '\$${product.price!.toStringAsFixed(2)}' : 'Free',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                              ],
                            ),
                            // Category and Status chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  avatar: Icon(_getCategoryIcon(product.category), size: 16, color: Theme.of(context).colorScheme.onPrimaryContainer),
                                  label: Text(product.category.displayName),
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  visualDensity: VisualDensity.compact,
                                ),
                                Chip(
                                  label: Text(product.status.displayName),
                                  backgroundColor: _getStatusColor(product.status).withValues(alpha: 0.2),
                                  labelStyle: TextStyle(color: _getStatusColor(product.status)),
                                  visualDensity: VisualDensity.compact,
                                ),
                                Chip(
                                  label: Text(product.condition.displayName),
                                  backgroundColor: _getConditionColor(product.condition).withValues(alpha: 0.2),
                                  labelStyle: TextStyle(color: _getConditionColor(product.condition)),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Description
                            Text(
                              product.description,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 16),

                            // Location
                            GestureDetector(
                              onTap: () {
                                final lat = product.location.latitude;
                                final lng = product.location.longitude;
                                final mapsUrl = Uri.parse(
                                  'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                                );
                                _launchUrl(context, mapsUrl.toString());
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        product.locationAddress,
                                        style: Theme.of(context).textTheme.bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Contact Section
                            if (product.contactEmail != null || product.contactPhone != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Contact Seller',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (product.contactEmail != null && product.contactEmail!.isNotEmpty)
                                        ActionChip(
                                          avatar: const Icon(Icons.email, size: 18),
                                          label: Text(product.contactEmail!),
                                          onPressed: () {
                                            final Uri emailUri = Uri(
                                              scheme: 'mailto',
                                              path: product.contactEmail,
                                            );
                                            _launchUrl(context, emailUri.toString());
                                          },
                                        ),
                                      if (product.contactPhone != null && product.contactPhone!.isNotEmpty)
                                        ActionChip(
                                          avatar: const Icon(Icons.phone, size: 18),
                                          label: Text(product.contactPhone!),
                                          onPressed: () {
                                            final Uri phoneUri = Uri(
                                              scheme: 'tel',
                                              path: product.contactPhone,
                                            );
                                            _launchUrl(context, phoneUri.toString());
                                          },
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions (like/comments)
                Builder(builder: (context) {
                  final auth = Provider.of<AuthService>(context, listen: false);
                  final currentUserId = auth.currentUser?.uid;
                  final isFavorited = currentUserId != null && product.favoritedBy.contains(currentUserId);
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            if (currentUserId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please sign in to favorite products')),
                              );
                              return;
                            }
                            try {
                              await Provider.of<ProductService>(context, listen: false)
                                  .toggleFavorite(productId, currentUserId);
                            } catch (e) {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text('Failed to favorite: $e')));
                            }
                          },
                          icon: Icon(isFavorited ? Icons.favorite : Icons.favorite_border),
                          label: Text(isFavorited ? 'Favorited (${product.favorites})' : 'Favorite (${product.favorites})'),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
          }

          return const Center(child: Text('Unsupported product format'));
        },
      ),
    );
  }

  void _launchUrl(BuildContext context, String urlString) async {
    try {
      final Uri uri = Uri.parse(urlString);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback: show dialog with contact info to copy
        if (context.mounted) {
          final contactValue = urlString.replaceFirst(RegExp(r'^(mailto:|tel:)'), '');
          final isMail = urlString.startsWith('mailto:');
          
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(isMail ? 'Email' : 'Phone'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    contactValue,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Close'),
                ),
                FilledButton(
                  onPressed: () {
                    final clipboard = contactValue;
                    // Copy to clipboard using basic method
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied: $contactValue'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Copy'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _DetailImageCarousel extends StatefulWidget {
  final List<String> photoUrls;
  const _DetailImageCarousel({required this.photoUrls});

  @override
  State<_DetailImageCarousel> createState() => _DetailImageCarouselState();
}

class _DetailImageCarouselState extends State<_DetailImageCarousel> {
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
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 500,
            minHeight: 300,
          ),
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
                itemCount: widget.photoUrls.length,
                itemBuilder: (context, index) {
                  return ImageFromString(src: widget.photoUrls[index], fit: BoxFit.contain);
                },
              ),
            ),
          ),
        ),
        if (widget.photoUrls.length > 1)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
              child: Text(
                '${_currentPageIndex + 1}/${widget.photoUrls.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}
