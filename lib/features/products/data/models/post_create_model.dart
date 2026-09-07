/// Data model representing a WooCommerce Product for creation and response.
/// Compatible with WooCommerce REST API v3: `POST /wp-json/wc/v3/products`.
class PostCreateModel {
  int? id;
  String? name;
  String? slug;
  String? permalink;
  String? dateCreated;
  String? dateCreatedGmt;
  String? dateModified;
  String? dateModifiedGmt;
  String? type;
  String? status;
  bool? featured;
  String? catalogVisibility;
  String? description;
  String? shortDescription;
  String? sku;
  String? price;
  String? regularPrice;
  String? salePrice;
  String? dateOnSaleFrom;
  String? dateOnSaleFromGmt;
  String? dateOnSaleTo;
  String? dateOnSaleToGmt;
  bool? onSale;
  bool? purchasable;
  int? totalSales;
  bool? virtual;
  bool? downloadable;
  List<ProductDownloadRef>? downloads;
  int? downloadLimit;
  int? downloadExpiry;
  String? externalUrl;
  String? buttonText;
  String? taxStatus;
  String? taxClass;
  bool? manageStock;
  int? stockQuantity;
  String? backorders;
  bool? backordersAllowed;
  bool? backordered;
  int? lowStockAmount;
  bool? soldIndividually;
  String? weight;
  Dimensions? dimensions;
  bool? shippingRequired;
  bool? shippingTaxable;
  String? shippingClass;
  int? shippingClassId;
  bool? reviewsAllowed;
  String? averageRating;
  int? ratingCount;
  List<int>? upsellIds;
  List<int>? crossSellIds;
  int? parentId;
  String? purchaseNote;
  List<ProductCategoryRef>? categories;
  List<dynamic>? brands;
  List<ProductTagRef>? tags;
  List<ProductImageRef>? images;
  List<ProductAttributeRef>? attributes;
  List<dynamic>? defaultAttributes;
  List<dynamic>? variations;
  List<dynamic>? groupedProducts;
  int? menuOrder;
  String? priceHtml;
  List<int>? relatedIds;
  List<Map<String, dynamic>>? metaData;
  String? stockStatus;
  bool? hasOptions;
  String? postPassword;
  String? globalUniqueId;
  String? permalinkTemplate;
  String? generatedSlug;
  Links? lLinks;

  PostCreateModel({
    this.id,
    this.name,
    this.slug,
    this.permalink,
    this.dateCreated,
    this.dateCreatedGmt,
    this.dateModified,
    this.dateModifiedGmt,
    this.type = 'simple',
    this.status = 'publish',
    this.featured = false,
    this.catalogVisibility = 'visible',
    this.description,
    this.shortDescription,
    this.sku,
    this.price,
    this.regularPrice,
    this.salePrice,
    this.dateOnSaleFrom,
    this.dateOnSaleFromGmt,
    this.dateOnSaleTo,
    this.dateOnSaleToGmt,
    this.onSale,
    this.purchasable,
    this.totalSales,
    this.virtual = false,
    this.downloadable = false,
    this.downloads,
    this.downloadLimit,
    this.downloadExpiry,
    this.externalUrl,
    this.buttonText,
    this.taxStatus = 'taxable',
    this.taxClass,
    this.manageStock = false,
    this.stockQuantity,
    this.backorders = 'no',
    this.backordersAllowed,
    this.backordered,
    this.lowStockAmount,
    this.soldIndividually = false,
    this.weight,
    this.dimensions,
    this.shippingRequired,
    this.shippingTaxable,
    this.shippingClass,
    this.shippingClassId,
    this.reviewsAllowed = true,
    this.averageRating,
    this.ratingCount,
    this.upsellIds,
    this.crossSellIds,
    this.parentId,
    this.purchaseNote,
    this.categories,
    this.brands,
    this.tags,
    this.images,
    this.attributes,
    this.defaultAttributes,
    this.variations,
    this.groupedProducts,
    this.menuOrder,
    this.priceHtml,
    this.relatedIds,
    this.metaData,
    this.stockStatus = 'instock',
    this.hasOptions,
    this.postPassword,
    this.globalUniqueId,
    this.permalinkTemplate,
    this.generatedSlug,
    this.lLinks,
  });

  PostCreateModel.fromJson(Map<String, dynamic> json) {
    id = _parseInt(json['id']);
    name = json['name']?.toString();
    slug = json['slug']?.toString();
    permalink = json['permalink']?.toString();
    dateCreated = json['date_created']?.toString();
    dateCreatedGmt = json['date_created_gmt']?.toString();
    dateModified = json['date_modified']?.toString();
    dateModifiedGmt = json['date_modified_gmt']?.toString();
    type = json['type']?.toString();
    status = json['status']?.toString();
    featured = json['featured'] as bool?;
    catalogVisibility = json['catalog_visibility']?.toString();
    description = json['description']?.toString();
    shortDescription = json['short_description']?.toString();
    sku = json['sku']?.toString();
    price = json['price']?.toString();
    regularPrice = json['regular_price']?.toString();
    salePrice = json['sale_price']?.toString();
    dateOnSaleFrom = json['date_on_sale_from']?.toString();
    dateOnSaleFromGmt = json['date_on_sale_from_gmt']?.toString();
    dateOnSaleTo = json['date_on_sale_to']?.toString();
    dateOnSaleToGmt = json['date_on_sale_to_gmt']?.toString();
    onSale = json['on_sale'] as bool?;
    purchasable = json['purchasable'] as bool?;
    totalSales = _parseInt(json['total_sales']);
    virtual = json['virtual'] as bool?;
    downloadable = json['downloadable'] as bool?;
    if (json['downloads'] != null && json['downloads'] is List) {
      downloads = (json['downloads'] as List)
          .whereType<Map<String, dynamic>>()
          .map((v) => ProductDownloadRef.fromJson(v))
          .toList();
    }
    downloadLimit = _parseInt(json['download_limit']);
    downloadExpiry = _parseInt(json['download_expiry']);
    externalUrl = json['external_url']?.toString();
    buttonText = json['button_text']?.toString();
    taxStatus = json['tax_status']?.toString();
    taxClass = json['tax_class']?.toString();
    manageStock = json['manage_stock'] as bool?;
    stockQuantity = _parseInt(json['stock_quantity']);
    backorders = json['backorders']?.toString();
    backordersAllowed = json['backorders_allowed'] as bool?;
    backordered = json['backordered'] as bool?;
    lowStockAmount = _parseInt(json['low_stock_amount']);
    soldIndividually = json['sold_individually'] as bool?;
    weight = json['weight']?.toString();
    dimensions = json['dimensions'] != null && json['dimensions'] is Map<String, dynamic>
        ? Dimensions.fromJson(json['dimensions'] as Map<String, dynamic>)
        : null;
    shippingRequired = json['shipping_required'] as bool?;
    shippingTaxable = json['shipping_taxable'] as bool?;
    shippingClass = json['shipping_class']?.toString();
    shippingClassId = _parseInt(json['shipping_class_id']);
    reviewsAllowed = json['reviews_allowed'] as bool?;
    averageRating = json['average_rating']?.toString();
    ratingCount = _parseInt(json['rating_count']);
    if (json['upsell_ids'] != null && json['upsell_ids'] is List) {
      upsellIds = (json['upsell_ids'] as List)
          .map((e) => _parseInt(e))
          .whereType<int>()
          .toList();
    }
    if (json['cross_sell_ids'] != null && json['cross_sell_ids'] is List) {
      crossSellIds = (json['cross_sell_ids'] as List)
          .map((e) => _parseInt(e))
          .whereType<int>()
          .toList();
    }
    parentId = _parseInt(json['parent_id']);
    purchaseNote = json['purchase_note']?.toString();
    if (json['categories'] != null && json['categories'] is List) {
      categories = (json['categories'] as List)
          .whereType<Map<String, dynamic>>()
          .map((v) => ProductCategoryRef.fromJson(v))
          .toList();
    }
    if (json['brands'] != null && json['brands'] is List) {
      brands = List<dynamic>.from(json['brands'] as List);
    }
    if (json['tags'] != null && json['tags'] is List) {
      tags = (json['tags'] as List)
          .whereType<Map<String, dynamic>>()
          .map((v) => ProductTagRef.fromJson(v))
          .toList();
    }
    if (json['images'] != null && json['images'] is List) {
      images = (json['images'] as List)
          .whereType<Map<String, dynamic>>()
          .map((v) => ProductImageRef.fromJson(v))
          .toList();
    }
    if (json['attributes'] != null && json['attributes'] is List) {
      attributes = (json['attributes'] as List)
          .whereType<Map<String, dynamic>>()
          .map((v) => ProductAttributeRef.fromJson(v))
          .toList();
    }
    if (json['default_attributes'] != null && json['default_attributes'] is List) {
      defaultAttributes = List<dynamic>.from(json['default_attributes'] as List);
    }
    if (json['variations'] != null && json['variations'] is List) {
      variations = List<dynamic>.from(json['variations'] as List);
    }
    if (json['grouped_products'] != null && json['grouped_products'] is List) {
      groupedProducts = List<dynamic>.from(json['grouped_products'] as List);
    }
    menuOrder = _parseInt(json['menu_order']);
    priceHtml = json['price_html']?.toString();
    if (json['related_ids'] != null && json['related_ids'] is List) {
      relatedIds = (json['related_ids'] as List)
          .map((e) => _parseInt(e))
          .whereType<int>()
          .toList();
    }
    if (json['meta_data'] != null && json['meta_data'] is List) {
      metaData = (json['meta_data'] as List)
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    stockStatus = json['stock_status']?.toString();
    hasOptions = json['has_options'] as bool?;
    postPassword = json['post_password']?.toString();
    globalUniqueId = json['global_unique_id']?.toString();
    permalinkTemplate = json['permalink_template']?.toString();
    generatedSlug = json['generated_slug']?.toString();
    lLinks = json['_links'] != null && json['_links'] is Map<String, dynamic>
        ? Links.fromJson(json['_links'] as Map<String, dynamic>)
        : null;
  }

  /// Converts model to payload containing ONLY valid writeable fields for `POST /wp-json/wc/v3/products`.
  /// Strips out read-only fields (e.g. id, date_created, price, total_sales, _links).
  Map<String, dynamic> toCreatePayload() {
    final Map<String, dynamic> data = <String, dynamic>{};

    if (name != null && name!.trim().isNotEmpty) {
      data['name'] = name!.trim();
    }
    if (type != null && type!.isNotEmpty) {
      data['type'] = type;
    }
    if (status != null && status!.isNotEmpty) {
      data['status'] = status;
    }
    if (featured != null) {
      data['featured'] = featured;
    }
    if (catalogVisibility != null && catalogVisibility!.isNotEmpty) {
      data['catalog_visibility'] = catalogVisibility;
    }
    if (description != null && description!.trim().isNotEmpty) {
      data['description'] = description!.trim();
    }
    if (shortDescription != null && shortDescription!.trim().isNotEmpty) {
      data['short_description'] = shortDescription!.trim();
    }
    if (sku != null && sku!.trim().isNotEmpty) {
      data['sku'] = sku!.trim();
    }
    if (regularPrice != null && regularPrice!.trim().isNotEmpty) {
      data['regular_price'] = regularPrice!.trim();
    }
    if (salePrice != null && salePrice!.trim().isNotEmpty) {
      data['sale_price'] = salePrice!.trim();
    }
    if (virtual != null) {
      data['virtual'] = virtual;
    }
    if (downloadable != null) {
      data['downloadable'] = downloadable;
    }
    if (taxStatus != null && taxStatus!.isNotEmpty) {
      data['tax_status'] = taxStatus;
    }
    if (taxClass != null && taxClass!.trim().isNotEmpty) {
      data['tax_class'] = taxClass!.trim();
    }
    if (manageStock != null) {
      data['manage_stock'] = manageStock;
    }
    if (manageStock == true && stockQuantity != null) {
      data['stock_quantity'] = stockQuantity;
    }
    if (stockStatus != null && stockStatus!.isNotEmpty) {
      data['stock_status'] = stockStatus;
    }
    if (backorders != null && backorders!.isNotEmpty) {
      data['backorders'] = backorders;
    }
    if (lowStockAmount != null) {
      data['low_stock_amount'] = lowStockAmount;
    }
    if (soldIndividually != null) {
      data['sold_individually'] = soldIndividually;
    }
    if (weight != null && weight!.trim().isNotEmpty) {
      data['weight'] = weight!.trim();
    }
    if (dimensions != null && !dimensions!.isEmpty) {
      data['dimensions'] = dimensions!.toJson();
    }
    if (shippingClass != null && shippingClass!.trim().isNotEmpty) {
      data['shipping_class'] = shippingClass!.trim();
    }
    if (reviewsAllowed != null) {
      data['reviews_allowed'] = reviewsAllowed;
    }
    if (purchaseNote != null && purchaseNote!.trim().isNotEmpty) {
      data['purchase_note'] = purchaseNote!.trim();
    }
    if (categories != null && categories!.isNotEmpty) {
      data['categories'] = categories!.map((v) => v.toWriteJson()).toList();
    }
    if (tags != null && tags!.isNotEmpty) {
      data['tags'] = tags!.map((v) => v.toWriteJson()).toList();
    }
    if (images != null && images!.isNotEmpty) {
      data['images'] = images!.map((v) => v.toWriteJson()).toList();
    }
    if (attributes != null && attributes!.isNotEmpty) {
      data['attributes'] = attributes!.map((v) => v.toWriteJson()).toList();
    }

    return data;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['slug'] = slug;
    data['permalink'] = permalink;
    data['date_created'] = dateCreated;
    data['date_created_gmt'] = dateCreatedGmt;
    data['date_modified'] = dateModified;
    data['date_modified_gmt'] = dateModifiedGmt;
    data['type'] = type;
    data['status'] = status;
    data['featured'] = featured;
    data['catalog_visibility'] = catalogVisibility;
    data['description'] = description;
    data['short_description'] = shortDescription;
    data['sku'] = sku;
    data['price'] = price;
    data['regular_price'] = regularPrice;
    data['sale_price'] = salePrice;
    data['date_on_sale_from'] = dateOnSaleFrom;
    data['date_on_sale_from_gmt'] = dateOnSaleFromGmt;
    data['date_on_sale_to'] = dateOnSaleTo;
    data['date_on_sale_to_gmt'] = dateOnSaleToGmt;
    data['on_sale'] = onSale;
    data['purchasable'] = purchasable;
    data['total_sales'] = totalSales;
    data['virtual'] = virtual;
    data['downloadable'] = downloadable;
    if (downloads != null) {
      data['downloads'] = downloads!.map((v) => v.toJson()).toList();
    }
    data['download_limit'] = downloadLimit;
    data['download_expiry'] = downloadExpiry;
    data['external_url'] = externalUrl;
    data['button_text'] = buttonText;
    data['tax_status'] = taxStatus;
    data['tax_class'] = taxClass;
    data['manage_stock'] = manageStock;
    data['stock_quantity'] = stockQuantity;
    data['backorders'] = backorders;
    data['backorders_allowed'] = backordersAllowed;
    data['backordered'] = backordered;
    data['low_stock_amount'] = lowStockAmount;
    data['sold_individually'] = soldIndividually;
    data['weight'] = weight;
    if (dimensions != null) {
      data['dimensions'] = dimensions!.toJson();
    }
    data['shipping_required'] = shippingRequired;
    data['shipping_taxable'] = shippingTaxable;
    data['shipping_class'] = shippingClass;
    data['shipping_class_id'] = shippingClassId;
    data['reviews_allowed'] = reviewsAllowed;
    data['average_rating'] = averageRating;
    data['rating_count'] = ratingCount;
    if (upsellIds != null) {
      data['upsell_ids'] = upsellIds;
    }
    if (crossSellIds != null) {
      data['cross_sell_ids'] = crossSellIds;
    }
    data['parent_id'] = parentId;
    data['purchase_note'] = purchaseNote;
    if (categories != null) {
      data['categories'] = categories!.map((v) => v.toJson()).toList();
    }
    if (brands != null) {
      data['brands'] = brands;
    }
    if (tags != null) {
      data['tags'] = tags!.map((v) => v.toJson()).toList();
    }
    if (images != null) {
      data['images'] = images!.map((v) => v.toJson()).toList();
    }
    if (attributes != null) {
      data['attributes'] = attributes!.map((v) => v.toJson()).toList();
    }
    if (defaultAttributes != null) {
      data['default_attributes'] = defaultAttributes;
    }
    if (variations != null) {
      data['variations'] = variations;
    }
    if (groupedProducts != null) {
      data['grouped_products'] = groupedProducts;
    }
    data['menu_order'] = menuOrder;
    data['price_html'] = priceHtml;
    if (relatedIds != null) {
      data['related_ids'] = relatedIds;
    }
    if (metaData != null) {
      data['meta_data'] = metaData;
    }
    data['stock_status'] = stockStatus;
    data['has_options'] = hasOptions;
    data['post_password'] = postPassword;
    data['global_unique_id'] = globalUniqueId;
    data['permalink_template'] = permalinkTemplate;
    data['generated_slug'] = generatedSlug;
    if (lLinks != null) {
      data['_links'] = lLinks!.toJson();
    }
    return data;
  }

  static int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val);
    return null;
  }
}

class Dimensions {
  String? length;
  String? width;
  String? height;

  Dimensions({this.length, this.width, this.height});

  bool get isEmpty =>
      (length == null || length!.isEmpty) &&
      (width == null || width!.isEmpty) &&
      (height == null || height!.isEmpty);

  Dimensions.fromJson(Map<String, dynamic> json) {
    length = json['length']?.toString();
    width = json['width']?.toString();
    height = json['height']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['length'] = length ?? '';
    data['width'] = width ?? '';
    data['height'] = height ?? '';
    return data;
  }
}

class ProductCategoryRef {
  int? id;
  String? name;
  String? slug;

  ProductCategoryRef({this.id, this.name, this.slug});

  ProductCategoryRef.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '');
    name = json['name']?.toString();
    slug = json['slug']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    if (name != null) data['name'] = name;
    if (slug != null) data['slug'] = slug;
    return data;
  }

  /// Writeable format for POST /wp-json/wc/v3/products
  Map<String, dynamic> toWriteJson() {
    if (id != null && id! > 0) {
      return {'id': id};
    }
    return {'name': name ?? ''};
  }
}

class ProductTagRef {
  int? id;
  String? name;
  String? slug;

  ProductTagRef({this.id, this.name, this.slug});

  ProductTagRef.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '');
    name = json['name']?.toString();
    slug = json['slug']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    if (name != null) data['name'] = name;
    if (slug != null) data['slug'] = slug;
    return data;
  }

  /// Writeable format for POST /wp-json/wc/v3/products
  Map<String, dynamic> toWriteJson() {
    if (id != null && id! > 0) {
      return {'id': id};
    }
    return {'name': name ?? ''};
  }
}

class ProductImageRef {
  int? id;
  String? src;
  String? name;
  String? alt;

  ProductImageRef({this.id, this.src, this.name, this.alt});

  ProductImageRef.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '');
    src = json['src']?.toString();
    name = json['name']?.toString();
    alt = json['alt']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    if (src != null) data['src'] = src;
    if (name != null) data['name'] = name;
    if (alt != null) data['alt'] = alt;
    return data;
  }

  /// Writeable format for POST /wp-json/wc/v3/products
  Map<String, dynamic> toWriteJson() {
    if (id != null && id! > 0) {
      return {'id': id};
    }
    return {'src': src ?? ''};
  }
}

class ProductAttributeRef {
  int? id;
  String? name;
  int? position;
  bool? visible;
  bool? variation;
  List<String>? options;

  ProductAttributeRef({
    this.id,
    this.name,
    this.position = 0,
    this.visible = true,
    this.variation = false,
    this.options,
  });

  ProductAttributeRef.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '');
    name = json['name']?.toString();
    position = json['position'] is int ? json['position'] : int.tryParse(json['position']?.toString() ?? '0');
    visible = json['visible'] as bool? ?? true;
    variation = json['variation'] as bool? ?? false;
    if (json['options'] != null && json['options'] is List) {
      options = (json['options'] as List).map((e) => e.toString()).toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    data['name'] = name ?? '';
    data['position'] = position ?? 0;
    data['visible'] = visible ?? true;
    data['variation'] = variation ?? false;
    data['options'] = options ?? [];
    return data;
  }

  Map<String, dynamic> toWriteJson() => toJson();
}

class ProductDownloadRef {
  String? id;
  String? name;
  String? file;

  ProductDownloadRef({this.id, this.name, this.file});

  ProductDownloadRef.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    name = json['name']?.toString();
    file = json['file']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['id'] = id;
    if (name != null) data['name'] = name;
    if (file != null) data['file'] = file;
    return data;
  }
}

class Links {
  List<Self>? self;
  List<Collection>? collection;

  Links({this.self, this.collection});

  Links.fromJson(Map<String, dynamic> json) {
    if (json['self'] != null && json['self'] is List) {
      self = (json['self'] as List)
          .whereType<Map<String, dynamic>>()
          .map((v) => Self.fromJson(v))
          .toList();
    }
    if (json['collection'] != null && json['collection'] is List) {
      collection = (json['collection'] as List)
          .whereType<Map<String, dynamic>>()
          .map((v) => Collection.fromJson(v))
          .toList();
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
