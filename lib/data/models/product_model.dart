class ProductModel {
  final String id;
  final String sku;
  final String name;
  final int? categoryId;
  final String? categoryName;
  final int stock;
  final int minStock;
  final String? location;
  final DateTime? createdAt;

  ProductModel({
    required this.id,
    required this.sku,
    required this.name,
    this.categoryId,
    this.categoryName,
    this.stock = 0,
    this.minStock = 5,
    this.location,
    this.createdAt,
  });

  /// True jika stok mencapai atau di bawah batas minimum
  bool get isLowStock => stock <= minStock;

  /// True jika stok habis total
  bool get isOutOfStock => stock <= 0;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Handle nested category join if present
    String? catName;
    if (json['categories'] != null && json['categories'] is Map) {
      catName = json['categories']['name'] as String?;
    } else if (json['category_name'] != null) {
      catName = json['category_name'] as String?;
    }

    return ProductModel(
      id: json['id'] as String,
      sku: json['sku'] as String,
      name: json['name'] as String,
      categoryId: json['category_id'] != null
          ? (json['category_id'] is int
              ? json['category_id'] as int
              : int.tryParse(json['category_id'].toString()))
          : null,
      categoryName: catName,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      minStock: (json['min_stock'] as num?)?.toInt() ?? 5,
      location: json['location'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      if (categoryId != null) 'category_id': categoryId,
      'stock': stock,
      'min_stock': minStock,
      if (location != null) 'location': location,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  ProductModel copyWith({
    String? id,
    String? sku,
    String? name,
    int? categoryId,
    String? categoryName,
    int? stock,
    int? minStock,
    String? location,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
