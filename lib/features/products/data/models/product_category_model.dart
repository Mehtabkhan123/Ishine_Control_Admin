import 'post_create_model.dart' show ProductImageRef;

/// Data model representing a WooCommerce Product Category for CRUD operations.
/// Compatible with WooCommerce REST API v3:
/// - `POST /wp-json/wc/v3/products/categories` (Create)
/// - `PUT /wp-json/wc/v3/products/categories/{{id}}` (Update)
/// - `DELETE /wp-json/wc/v3/products/categories/{{id}}` (Delete)
/// - `GET /wp-json/wc/v3/products/categories` (List & Retrieve)
class ProductCategoryModel {
  int? id;
  String? name;
  String? slug;
  int? parent;
  String? description;
  String? display;
  ProductImageRef? image;
  int? menuOrder;
  int? count;

  ProductCategoryModel({
    this.id,
    this.name,
    this.slug,
    this.parent,
    this.description,
    this.display,
    this.image,
    this.menuOrder,
    this.count,
  });

  ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int
        ? json['id']
        : int.tryParse(json['id']?.toString() ?? '');
    name = json['name']?.toString();
    slug = json['slug']?.toString();
    parent = json['parent'] is int
        ? json['parent']
        : int.tryParse(json['parent']?.toString() ?? '');
    description = json['description']?.toString();
    display = json['display']?.toString();
    menuOrder = json['menu_order'] is int
        ? json['menu_order']
        : int.tryParse(json['menu_order']?.toString() ?? '');
    count = json['count'] is int
        ? json['count']
        : int.tryParse(json['count']?.toString() ?? '');
    if (json['image'] != null) {
      if (json['image'] is Map<String, dynamic>) {
        image = ProductImageRef.fromJson(json['image'] as Map<String, dynamic>);
      } else if (json['image'] is Map) {
        image = ProductImageRef.fromJson(
            Map<String, dynamic>.from(json['image'] as Map));
      } else if (json['image'] is String && (json['image'] as String).isNotEmpty) {
        image = ProductImageRef(src: json['image'] as String);
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    if (name != null) data['name'] = name;
    if (slug != null) data['slug'] = slug;
    if (parent != null) data['parent'] = parent;
    if (description != null) data['description'] = description;
    if (display != null) data['display'] = display;
    if (menuOrder != null) data['menu_order'] = menuOrder;
    if (count != null) data['count'] = count;
    if (image != null) data['image'] = image!.toJson();
    return data;
  }

  /// Writeable payload for POST /wp-json/wc/v3/products/categories
  Map<String, dynamic> toCreatePayload() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (name != null && name!.trim().isNotEmpty) {
      data['name'] = name!.trim();
    }
    if (slug != null && slug!.trim().isNotEmpty) {
      data['slug'] = slug!.trim();
    }
    if (parent != null && parent! > 0) {
      data['parent'] = parent;
    } else {
      data['parent'] = 0;
    }
    if (description != null && description!.trim().isNotEmpty) {
      data['description'] = description!.trim();
    }
    if (display != null && display!.trim().isNotEmpty && display != 'default') {
      data['display'] = display!.trim();
    }
    if (image != null) {
      if (image!.id != null && image!.id! > 0) {
        data['image'] = {'id': image!.id};
      } else if (image!.src != null && image!.src!.trim().isNotEmpty) {
        data['image'] = {'src': image!.src!.trim()};
      }
    }
    if (menuOrder != null) {
      data['menu_order'] = menuOrder;
    }
    return data;
  }

  /// Writeable payload for PUT /wp-json/wc/v3/products/categories/{{categoryId}}
  Map<String, dynamic> toUpdatePayload() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (name != null && name!.trim().isNotEmpty) {
      data['name'] = name!.trim();
    }
    if (slug != null && slug!.trim().isNotEmpty) {
      data['slug'] = slug!.trim();
    }
    if (parent != null) {
      data['parent'] = parent! > 0 ? parent : 0;
    }
    if (description != null) {
      data['description'] = description!.trim();
    }
    if (display != null && display!.trim().isNotEmpty) {
      data['display'] = display!.trim();
    }
    if (image != null) {
      if (image!.id != null && image!.id! > 0) {
        data['image'] = {'id': image!.id};
      } else if (image!.src != null && image!.src!.trim().isNotEmpty) {
        data['image'] = {'src': image!.src!.trim()};
      }
    }
    if (menuOrder != null) {
      data['menu_order'] = menuOrder;
    }
    return data;
  }

  /// Writeable format for POST /wp-json/wc/v3/products
  Map<String, dynamic> toWriteJson() {
    if (id != null && id! > 0) {
      return {'id': id};
    }
    return {'name': name ?? ''};
  }

  /// Writeable payload format for POST /wp-json/wc/v3/products/categories
  Map<String, dynamic> toCreateCategoryPayload() => toCreatePayload();

  ProductCategoryModel copyWith({
    int? id,
    String? name,
    String? slug,
    int? parent,
    String? description,
    String? display,
    ProductImageRef? image,
    int? menuOrder,
    int? count,
  }) {
    return ProductCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      parent: parent ?? this.parent,
      description: description ?? this.description,
      display: display ?? this.display,
      image: image ?? this.image,
      menuOrder: menuOrder ?? this.menuOrder,
      count: count ?? this.count,
    );
  }
}

/// Type alias for backward compatibility across existing references
typedef ProductCategoryRef = ProductCategoryModel;
