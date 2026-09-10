import 'dart:convert';
import 'post_create_model.dart' show ProductImageRef;

List<GetCategoriesModel> getCategoriesModelFromJson(String str) =>
    List<GetCategoriesModel>.from(
        json.decode(str).map((x) => GetCategoriesModel.fromJson(x)));

String getCategoriesModelToJson(List<GetCategoriesModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

/// Model representing a WooCommerce Product Category.
/// Maps strictly to `GET /wp-json/wc/v3/products/categories`.
class GetCategoriesModel {
  int? id;
  String? name;
  String? slug;
  int? parent;
  String? description;
  String? display;
  dynamic image;
  int? menuOrder;
  int? count;
  Links? lLinks;

  GetCategoriesModel({
    this.id,
    this.name,
    this.slug,
    this.parent,
    this.description,
    this.display,
    this.image,
    this.menuOrder,
    this.count,
    this.lLinks,
  });

  GetCategoriesModel.fromJson(Map<String, dynamic> json) {
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
    if (json['image'] is Map<String, dynamic>) {
      image = ProductImageRef.fromJson(json['image'] as Map<String, dynamic>);
    } else if (json['image'] is Map) {
      image = ProductImageRef.fromJson(
          Map<String, dynamic>.from(json['image'] as Map));
    } else {
      image = json['image'];
    }
    menuOrder = json['menu_order'] is int
        ? json['menu_order']
        : int.tryParse(json['menu_order']?.toString() ?? '');
    count = json['count'] is int
        ? json['count']
        : int.tryParse(json['count']?.toString() ?? '');
    lLinks = json['_links'] != null ? Links.fromJson(json['_links']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['slug'] = slug;
    data['parent'] = parent;
    data['description'] = description;
    data['display'] = display;
    if (image != null) {
      if (image is ProductImageRef) {
        data['image'] = (image as ProductImageRef).toJson();
      } else {
        data['image'] = image;
      }
    } else {
      data['image'] = null;
    }
    data['menu_order'] = menuOrder;
    data['count'] = count;
    if (lLinks != null) {
      data['_links'] = lLinks!.toJson();
    }
    return data;
  }

  /// Whether this category is a top-level root category (`parent == 0` or null).
  bool get isMainCategory => parent == null || parent == 0;

  /// Human-readable category display name.
  String get displayName =>
      (name != null && name!.trim().isNotEmpty) ? name!.trim() : 'Category #$id';

  /// Slug for URL/query reference.
  String get displaySlug => slug ?? '';

  /// Number of products under this category.
  int get productCount => count ?? 0;

  /// Sort priority index in WooCommerce menu order.
  int get sortOrder => menuOrder ?? 0;

  /// Safely extracts image URL from image property (Map, String, or ProductImageRef).
  String? get imageUrl {
    if (image == null) return null;
    if (image is ProductImageRef) {
      return (image as ProductImageRef).src;
    }
    if (image is Map) {
      return (image as Map)['src']?.toString();
    }
    if (image is String && (image as String).isNotEmpty) {
      return image as String;
    }
    return null;
  }

  /// Converts image to [ProductImageRef] if available.
  ProductImageRef? get imageRef {
    if (image == null) return null;
    if (image is ProductImageRef) return image as ProductImageRef;
    if (image is Map<String, dynamic>) {
      return ProductImageRef.fromJson(image as Map<String, dynamic>);
    }
    if (image is Map) {
      return ProductImageRef.fromJson(
          Map<String, dynamic>.from(image as Map));
    }
    if (image is String && (image as String).isNotEmpty) {
      return ProductImageRef(src: image as String);
    }
    return null;
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
    final ref = imageRef;
    if (ref != null) {
      if (ref.id != null && ref.id! > 0) {
        data['image'] = {'id': ref.id};
      } else if (ref.src != null && ref.src!.trim().isNotEmpty) {
        data['image'] = {'src': ref.src!.trim()};
      }
    }
    if (menuOrder != null) {
      data['menu_order'] = menuOrder;
    }
    return data;
  }

  /// Alias for compatibility
  Map<String, dynamic> toCreateCategoryPayload() => toCreatePayload();

  /// Alias for compatibility
  Map<String, dynamic> toUpdateCategoryPayload() => toUpdatePayload();

  /// Writeable payload for PUT /wp-json/wc/v3/products/categories/{{id}}
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
    final ref = imageRef;
    if (ref != null) {
      if (ref.id != null && ref.id! > 0) {
        data['image'] = {'id': ref.id};
      } else if (ref.src != null && ref.src!.trim().isNotEmpty) {
        data['image'] = {'src': ref.src!.trim()};
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

  GetCategoriesModel copyWith({
    int? id,
    String? name,
    String? slug,
    int? parent,
    String? description,
    String? display,
    dynamic image,
    int? menuOrder,
    int? count,
    Links? lLinks,
  }) {
    return GetCategoriesModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      parent: parent ?? this.parent,
      description: description ?? this.description,
      display: display ?? this.display,
      image: image ?? this.image,
      menuOrder: menuOrder ?? this.menuOrder,
      count: count ?? this.count,
      lLinks: lLinks ?? this.lLinks,
    );
  }
}

class Links {
  List<Self>? self;
  List<Collection>? collection;
  List<Up>? up;

  Links({this.self, this.collection, this.up});

  Links.fromJson(Map<String, dynamic> json) {
    if (json['self'] != null && json['self'] is List) {
      self = <Self>[];
      for (final v in json['self'] as List) {
        if (v is Map<String, dynamic>) {
          self!.add(Self.fromJson(v));
        }
      }
    }
    if (json['collection'] != null && json['collection'] is List) {
      collection = <Collection>[];
      for (final v in json['collection'] as List) {
        if (v is Map<String, dynamic>) {
          collection!.add(Collection.fromJson(v));
        }
      }
    }
    if (json['up'] != null && json['up'] is List) {
      up = <Up>[];
      for (final v in json['up'] as List) {
        if (v is Map<String, dynamic>) {
          up!.add(Up.fromJson(v));
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (self != null) {
      data['self'] = self!.map((v) => v.toJson()).toList();
    }
    if (collection != null) {
      data['collection'] = collection!.map((v) => v.toJson()).toList();
    }
    if (up != null) {
      data['up'] = up!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Self {
  String? href;
  TargetHints? targetHints;

  Self({this.href, this.targetHints});

  Self.fromJson(Map<String, dynamic> json) {
    href = json['href']?.toString();
    targetHints = json['targetHints'] != null && json['targetHints'] is Map<String, dynamic>
        ? TargetHints.fromJson(json['targetHints'] as Map<String, dynamic>)
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['href'] = href;
    if (targetHints != null) {
      data['targetHints'] = targetHints!.toJson();
    }
    return data;
  }
}

class TargetHints {
  List<String>? allow;

  TargetHints({this.allow});

  TargetHints.fromJson(Map<String, dynamic> json) {
    if (json['allow'] != null && json['allow'] is List) {
      allow = (json['allow'] as List).map((e) => e.toString()).toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['allow'] = allow;
    return data;
  }
}

class Collection {
  String? href;

  Collection({this.href});

  Collection.fromJson(Map<String, dynamic> json) {
    href = json['href']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['href'] = href;
    return data;
  }
}

class Up {
  String? href;

  Up({this.href});

  Up.fromJson(Map<String, dynamic> json) {
    href = json['href']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['href'] = href;
    return data;
  }
}
