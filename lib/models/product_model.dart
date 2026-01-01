import 'package:latlong2/latlong.dart';

enum ProductStatus {
  available('Available'),
  onsale('On Sale'),
  soldOut('Sold Out'),
  reserved('Reserved'),
  free('Free');

  

  const ProductStatus(this.displayName);
  final String displayName;
}
enum ProductCondition {
  newCondition('New'),
  likeNew('Like New'),
  good('Good'),
  fair('Fair'),
  poor('Poor');

  const ProductCondition(this.displayName);
  final String displayName;
}

enum ProductCategory {
  electronics('Electronics'),
  furniture('Furniture'),
  clothing('Clothing'),
  books('Books'),
  toys('Toys'),
  vehicles('Vehicles'),
  homegarden('Home & Garden'),
  sports('Sports & Outdoors'),
  healthbeauty('Health & Beauty'),
  toolsandequipment('Tools & Equipment'),
  other('Other');

  const ProductCategory(this.displayName);
  final String displayName;
}

class Product {
  final String? id;
  final String title;
  final String description;
  final double? price;
  final ProductStatus status;
  final ProductCategory category;
  final List<String> photoUrls;
  final LatLng location;
  final String locationAddress;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String? contactEmail;
  final String? contactPhone;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final ProductCondition condition;
  final int favorites;
  final List<String> favoritedBy;

  const Product({
    this.id,
    required this.title,
    required this.description,
    this.price,
    required this.category,
    required this.photoUrls,
    required this.location,
    required this.locationAddress,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    this.contactEmail,
    this.contactPhone,
    required this.createdAt,
    this.updatedAt,
    required this.status,
    required this.condition,
    this.favorites = 0,
    this.favoritedBy = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'photoUrls': photoUrls,
      'price': price,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'locationAddress': locationAddress,
      'userId': userId,
      'userName': userName,
      if (userPhotoUrl != null) 'userPhotoUrl': userPhotoUrl,
      if (contactEmail != null) 'contactEmail': contactEmail,
      if (contactPhone != null) 'contactPhone': contactPhone,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'status': status.name,
      'condition': condition.name,
      'favorites': favorites,
      'favoritedBy': favoritedBy,
    };
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    final categoryName = map['category'] as String?;
    final statusName = map['status'] as String?;
    final conditionName = map['condition'] as String?;

    return Product(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: categoryName != null
          ? ProductCategory.values.firstWhere(
              (e) => e.name == categoryName,
              orElse: () => ProductCategory.other,
            )
          : ProductCategory.other,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      photoUrls: (map['photoUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      location: LatLng(
        (map['latitude'] as num?)?.toDouble() ?? 0.0,
        (map['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      locationAddress: map['locationAddress'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userPhotoUrl: map['userPhotoUrl'] as String?,
      contactEmail: map['contactEmail'] as String?,
      contactPhone: map['contactPhone'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      status: statusName != null
          ? ProductStatus.values.firstWhere(
              (e) => e.name == statusName,
              orElse: () => ProductStatus.available,
            ) : ProductStatus.available,
      condition: conditionName != null
          ? ProductCondition.values.firstWhere(
              (e) => e.name == conditionName,
              orElse: () => ProductCondition.good,
            ) : ProductCondition.good,
      favorites: (map['favorites'] as num?)?.toInt() ?? 0,
      favoritedBy: (map['favoritedBy'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Product copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    ProductStatus? status,
    ProductCategory? category,
    List<String>? photoUrls,
    LatLng? location,
    String? locationAddress,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? contactEmail,
    String? contactPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
    ProductCondition? condition,
    int? favorites, 
    List<String>? favoritedBy,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      photoUrls: photoUrls ?? this.photoUrls,
      location: location ?? this.location,
      locationAddress: locationAddress ?? this.locationAddress,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      condition: condition ?? this.condition,
      favorites: favorites ?? this.favorites,
      favoritedBy: favoritedBy ?? this.favoritedBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
