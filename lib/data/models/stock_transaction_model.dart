class StockTransactionModel {
  final String id;
  final String productId;
  final String? productName;
  final String? productSku;
  final String? userId;
  final String? userName;
  final String type; // 'IN' or 'OUT'
  final int quantity;
  final String? notes;
  final DateTime? createdAt;

  StockTransactionModel({
    required this.id,
    required this.productId,
    this.productName,
    this.productSku,
    this.userId,
    this.userName,
    required this.type,
    required this.quantity,
    this.notes,
    this.createdAt,
  });

  bool get isInbound => type.toUpperCase() == 'IN';
  bool get isOutbound => type.toUpperCase() == 'OUT';

  factory StockTransactionModel.fromJson(Map<String, dynamic> json) {
    String? prodName;
    String? prodSku;
    if (json['products'] != null && json['products'] is Map) {
      prodName = json['products']['name'] as String?;
      prodSku = json['products']['sku'] as String?;
    } else {
      prodName = json['product_name'] as String?;
      prodSku = json['product_sku'] as String?;
    }

    String? uName;
    if (json['profiles'] != null && json['profiles'] is Map) {
      uName = json['profiles']['full_name'] as String?;
    } else {
      uName = json['user_name'] as String?;
    }

    return StockTransactionModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: prodName,
      productSku: prodSku,
      userId: json['user_id'] as String?,
      userName: uName,
      type: (json['type'] as String?)?.toUpperCase() ?? 'IN',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      if (userId != null) 'user_id': userId,
      'type': type,
      'quantity': quantity,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
