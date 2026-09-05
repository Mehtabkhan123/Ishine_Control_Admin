import 'dart:convert';
import 'sales_report_model.dart';

List<TopSellerModel> topSellerModelListFromJson(String str) =>
    List<TopSellerModel>.from(
      json.decode(str).map((x) => TopSellerModel.fromJson(x as Map<String, dynamic>)),
    );

String topSellerModelListToJson(List<TopSellerModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

/// Model representing a WooCommerce Top Seller item from `/reports/top_sellers`.
class TopSellerModel {
  final String name;
  final int productId;
  final int quantity;
  final Links? links;
  final String? imageUrl;

  TopSellerModel({
    required this.name,
    required this.productId,
    required this.quantity,
    this.links,
    this.imageUrl,
  });

  factory TopSellerModel.fromJson(Map<String, dynamic> json) {
    // 1. Safe product title/name extraction
    final rawName = json['name'] ?? json['title'] ?? 'Product #${json['product_id'] ?? 'Unknown'}';
    final name = rawName.toString();

    // 2. Safe product ID extraction
    int id = 0;
    if (json['product_id'] is num) {
      id = (json['product_id'] as num).toInt();
    } else if (json['product_id'] != null) {
      id = int.tryParse(json['product_id'].toString()) ?? 0;
    }

    // 3. Safe quantity extraction
    int qty = 0;
    if (json['quantity'] is num) {
      qty = (json['quantity'] as num).toInt();
    } else if (json['quantity'] != null) {
      qty = int.tryParse(json['quantity'].toString()) ?? 0;
    }

    // 4. Links
    Links? links;
    if (json['_links'] is Map<String, dynamic>) {
      links = Links.fromJson(json['_links'] as Map<String, dynamic>);
    }

    // 5. Image URL if provided directly or populated
    final imageUrl = json['image_url']?.toString();

    return TopSellerModel(
      name: name,
      productId: id,
      quantity: qty,
      links: links,
      imageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'name': name,
      'product_id': productId,
      'quantity': quantity,
    };
    if (links != null) {
      data['_links'] = links!.toJson();
    }
    if (imageUrl != null) {
      data['image_url'] = imageUrl;
    }
    return data;
  }

  TopSellerModel copyWith({
    String? name,
    int? productId,
    int? quantity,
    Links? links,
    String? imageUrl,
  }) {
    return TopSellerModel(
      name: name ?? this.name,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      links: links ?? this.links,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
