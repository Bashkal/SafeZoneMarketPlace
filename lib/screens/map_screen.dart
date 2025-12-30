import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _fallbackLocation = LatLng(40.7128, -74.0060); // NYC
  static const double _defaultZoom = 13;

  late MapController _mapController;
  LatLng _currentLocation = _fallbackLocation;
  Product? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductService>(context, listen: false).fetchProducts();
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_currentLocation, _defaultZoom);
      }
    } catch (e) {
      // Use default location if getting current location fails
      _mapController.move(_currentLocation, _defaultZoom);
    }
  }

  Color _getMarkerColor(ProductStatus status) {
   
    switch (status) {
      case ProductStatus.available:
        return Colors.green;
      case ProductStatus.free:
        return Colors.blue;
      case ProductStatus.soldOut:
        return Colors.grey;
      case ProductStatus.onsale:
        return Colors.red;
      case ProductStatus.reserved:
        return Colors.orange;  
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

  void _openSearch() {
    final productService = Provider.of<ProductService>(context, listen: false);
    showSearch(
      context: context,
      delegate: MapSearchDelegate(
        products: productService.products,
        onProductSelected: (product) {
          setState(() {
            _selectedProduct = product;
            _mapController.move(product.location, _defaultZoom);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<ProductService>(context, listen: false).fetchProducts();
            },
            tooltip: 'Refresh products',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _mapController.move(_currentLocation, _defaultZoom);
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
            tooltip: 'Search products',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: _defaultZoom,
              minZoom: 5,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.safezonemarketplace',
              ),
              MarkerLayer(
                markers: [
                  // Current location marker
                  Marker(
                    point: _currentLocation,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                  ),
                  // Product markers
                  ...productService.products.map((product) {
                    return Marker(
                      point: product.location,
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedProduct = product;
                          });
                        },
                        child: Icon(
                          _getCategoryIcon(product.category),
                          color: _getMarkerColor(product.status),
                          size: 32,
                          shadows: const [
                            Shadow(blurRadius: 4, color: Colors.black45),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Product details card
          if (_selectedProduct != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedProduct!.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          //Price
                          Text(
                            '\$${_selectedProduct!.price.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _selectedProduct = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(
                            label: Text(_selectedProduct!.category.displayName),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                          ),
                          const SizedBox(width: 4,),
                          Chip(
                            label: Text(_selectedProduct!.status.displayName),
                            backgroundColor: _getMarkerColor(
                              _selectedProduct!.status,
                            ).withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              color: _getMarkerColor(_selectedProduct!.status),
                            ),
                          ),
                          const SizedBox(width: 4,),
                          Chip(
                            label: Text(_selectedProduct!.condition.displayName),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedProduct!.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _selectedProduct!.locationAddress,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () {
                          final id = _selectedProduct!.id;
                          if (id == null || id.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Unable to open product: missing ID')),
                            );
                            return;
                          }
                          Navigator.of(context).pushNamed(
                            '/product',
                            arguments: id,
                          );
                        },
                        child: const Text('View Details'),
                      ),
                    ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Legend
          Positioned(
            top: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _LegendItem(
                      color: Colors.green,
                      label: 'Available',
                    ),
                    const _LegendItem(
                      color: Colors.blue,
                      label: 'Free',
                    ),
                    const _LegendItem(
                      color: Colors.red,
                      label: 'On Sale',
                    ),
                    const _LegendItem(
                      color: Colors.orange,
                      label: 'Reserved',
                    ),
                    const _LegendItem(
                      color: Colors.grey,
                      label: 'Sold Out',
                    ),
                    
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

// Search Delegate for map screen
class MapSearchDelegate extends SearchDelegate<Product?> {
  final List<Product> products;
  final Function(Product) onProductSelected;

  MapSearchDelegate({required this.products, required this.onProductSelected});

  @override
  String get searchFieldLabel => 'Search products on map';

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

  Color _getStatusColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.available:
        return Colors.green;
      case ProductStatus.free:
        return Colors.blue;
      case ProductStatus.soldOut:
        return Colors.grey;
      case ProductStatus.onsale:
        return Colors.red;
      case ProductStatus.reserved:
        return Colors.orange;
      
    }
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
              'Search products',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Find products by title, category, or location',
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
          product.locationAddress.toLowerCase().contains(searchQuery);
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
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _getStatusColor(product.status).withValues(alpha: 0.2),
            child: Icon(
              Icons.location_on,
              color: _getStatusColor(product.status),
            ),
          ),
          title: Text(
            product.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.category.displayName,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              //Price
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                product.locationAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          trailing: Chip(
            label: Text(
              product.status.displayName,
              style: const TextStyle(fontSize: 11),
            ),
            backgroundColor: _getStatusColor(product.status).withValues(alpha: 0.2),
            labelStyle: TextStyle(color: _getStatusColor(product.status)),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
          ),
          onTap: () {
            onProductSelected(product);
            close(context, product);
          },
        );
      },
    );
  }
}
