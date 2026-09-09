class GETCouponReportModel {
  int? id;
  String? code;
  String? amount;
  String? status;
  String? dateCreated;
  String? dateCreatedGmt;
  String? dateModified;
  String? dateModifiedGmt;
  String? discountType;
  String? description;
  String? dateExpires;
  String? dateExpiresGmt;
  int? usageCount;
  bool? individualUse;
  List<dynamic>? productIds;
  List<dynamic>? excludedProductIds;
  dynamic usageLimit;
  dynamic usageLimitPerUser;
  dynamic limitUsageToXItems;
  bool? freeShipping;
  List<dynamic>? productCategories;
  List<dynamic>? excludedProductCategories;
  bool? excludeSaleItems;
  String? minimumAmount;
  String? maximumAmount;
  List<dynamic>? emailRestrictions;
  List<String>? usedBy;
  List<CouponMetaData>? metaData;
  CouponLinks? lLinks;

  GETCouponReportModel({
    this.id,
    this.code,
    this.amount,
    this.status,
    this.dateCreated,
    this.dateCreatedGmt,
    this.dateModified,
    this.dateModifiedGmt,
    this.discountType,
    this.description,
    this.dateExpires,
    this.dateExpiresGmt,
    this.usageCount,
    this.individualUse,
    this.productIds,
    this.excludedProductIds,
    this.usageLimit,
    this.usageLimitPerUser,
    this.limitUsageToXItems,
    this.freeShipping,
    this.productCategories,
    this.excludedProductCategories,
    this.excludeSaleItems,
    this.minimumAmount,
    this.maximumAmount,
    this.emailRestrictions,
    this.usedBy,
    this.metaData,
    this.lLinks,
  });

  GETCouponReportModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    code = json['code'];
    amount = json['amount']?.toString();
    status = json['status'];
    dateCreated = json['date_created'];
    dateCreatedGmt = json['date_created_gmt'];
    dateModified = json['date_modified'];
    dateModifiedGmt = json['date_modified_gmt'];
    discountType = json['discount_type'];
    description = json['description'];
    dateExpires = json['date_expires'];
    dateExpiresGmt = json['date_expires_gmt'];
    usageCount = json['usage_count'] is int
        ? json['usage_count']
        : int.tryParse(json['usage_count']?.toString() ?? '');
    individualUse = json['individual_use'];

    if (json['product_ids'] != null) {
      productIds = List<dynamic>.from(json['product_ids']);
    }
    if (json['excluded_product_ids'] != null) {
      excludedProductIds = List<dynamic>.from(json['excluded_product_ids']);
    }

    usageLimit = json['usage_limit'];
    usageLimitPerUser = json['usage_limit_per_user'];
    limitUsageToXItems = json['limit_usage_to_x_items'];
    freeShipping = json['free_shipping'];

    if (json['product_categories'] != null) {
      productCategories = List<dynamic>.from(json['product_categories']);
    }
    if (json['excluded_product_categories'] != null) {
      excludedProductCategories =
          List<dynamic>.from(json['excluded_product_categories']);
    }

    excludeSaleItems = json['exclude_sale_items'];
    minimumAmount = json['minimum_amount']?.toString();
    maximumAmount = json['maximum_amount']?.toString();

    if (json['email_restrictions'] != null) {
      emailRestrictions = List<dynamic>.from(json['email_restrictions']);
    }

    if (json['used_by'] != null) {
      usedBy = List<String>.from(json['used_by'].map((e) => e.toString()));
    }

    if (json['meta_data'] != null) {
      metaData = <CouponMetaData>[];
      for (final v in json['meta_data']) {
        if (v is Map<String, dynamic>) {
          metaData!.add(CouponMetaData.fromJson(v));
        }
      }
    }

    lLinks = json['_links'] != null
        ? CouponLinks.fromJson(json['_links'] as Map<String, dynamic>)
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['code'] = code;
    data['amount'] = amount;
    data['status'] = status;
    data['date_created'] = dateCreated;
    data['date_created_gmt'] = dateCreatedGmt;
    data['date_modified'] = dateModified;
    data['date_modified_gmt'] = dateModifiedGmt;
    data['discount_type'] = discountType;
    data['description'] = description;
    data['date_expires'] = dateExpires;
    data['date_expires_gmt'] = dateExpiresGmt;
    data['usage_count'] = usageCount;
    data['individual_use'] = individualUse;
    if (productIds != null) {
      data['product_ids'] = productIds;
    }
    if (excludedProductIds != null) {
      data['excluded_product_ids'] = excludedProductIds;
    }
    data['usage_limit'] = usageLimit;
    data['usage_limit_per_user'] = usageLimitPerUser;
    data['limit_usage_to_x_items'] = limitUsageToXItems;
    data['free_shipping'] = freeShipping;
    if (productCategories != null) {
      data['product_categories'] = productCategories;
    }
    if (excludedProductCategories != null) {
      data['excluded_product_categories'] = excludedProductCategories;
    }
    data['exclude_sale_items'] = excludeSaleItems;
    data['minimum_amount'] = minimumAmount;
    data['maximum_amount'] = maximumAmount;
    if (emailRestrictions != null) {
      data['email_restrictions'] = emailRestrictions;
    }
    data['used_by'] = usedBy;
    if (metaData != null) {
      data['meta_data'] = metaData!.map((v) => v.toJson()).toList();
    }
    if (lLinks != null) {
      data['_links'] = lLinks!.toJson();
    }
    return data;
  }

  // --- Convenience Getters ---

  /// Human-readable formatted discount string (e.g. "15%" or "$20.00").
  String get formattedDiscount {
    final amt = amount ?? '0';
    final parsed = double.tryParse(amt);
    final amtFormatted = parsed != null ? parsed.toStringAsFixed(parsed.truncateToDouble() == parsed ? 0 : 2) : amt;

    switch (discountType?.toLowerCase()) {
      case 'percent':
        return '$amtFormatted%';
      case 'fixed_cart':
        return '\$$amtFormatted';
      case 'fixed_product':
        return '\$$amtFormatted / item';
      default:
        return amtFormatted.isNotEmpty ? '\$$amtFormatted' : 'Special offer';
    }
  }

  /// Readable name for the discount type.
  String get discountTypeDisplayName {
    switch (discountType?.toLowerCase()) {
      case 'percent':
        return 'Percentage Discount';
      case 'fixed_cart':
        return 'Fixed Cart Discount';
      case 'fixed_product':
        return 'Fixed Product Discount';
      default:
        if (discountType != null && discountType!.isNotEmpty) {
          final words = discountType!.replaceAll('_', ' ').split(' ');
          return words.map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
        }
        return 'Discount';
    }
  }

  /// Safe parsed DateTime from [dateExpires].
  DateTime? get parsedDateExpires {
    if (dateExpires == null || dateExpires!.trim().isEmpty) return null;
    return DateTime.tryParse(dateExpires!);
  }

  /// Safe parsed DateTime from [dateCreated].
  DateTime? get parsedDateCreated {
    if (dateCreated == null || dateCreated!.trim().isEmpty) return null;
    return DateTime.tryParse(dateCreated!);
  }

  /// Whether this coupon is currently expired based on dateExpires.
  bool get isExpired {
    final expires = parsedDateExpires;
    if (expires == null) return false;
    return expires.isBefore(DateTime.now());
  }

  /// Display text for usage count vs usage limit.
  String get usageDisplay {
    final count = usageCount ?? 0;
    if (usageLimit != null && usageLimit.toString().isNotEmpty && usageLimit.toString() != '0') {
      return '$count / $usageLimit';
    }
    return '$count used';
  }

  /// Display text for minimum spend requirement.
  String get minSpendDisplay {
    if (minimumAmount != null &&
        minimumAmount!.trim().isNotEmpty &&
        minimumAmount != '0.00' &&
        minimumAmount != '0') {
      return '\$$minimumAmount min spend';
    }
    return 'No minimum';
  }

  /// Display text for maximum spend requirement.
  String get maxSpendDisplay {
    if (maximumAmount != null &&
        maximumAmount!.trim().isNotEmpty &&
        maximumAmount != '0.00' &&
        maximumAmount != '0') {
      return '\$$maximumAmount max spend';
    }
    return 'No maximum';
  }

  /// Capitalized status (e.g. "Publish", "Draft", "Expired").
  String get statusDisplayName {
    if (isExpired) return 'Expired';
    if (status == null || status!.trim().isEmpty) return 'Active';
    final s = status!.trim();
    if (s.toLowerCase() == 'publish') return 'Active';
    return '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
  }
}

class CouponMetaData {
  int? id;
  String? key;
  dynamic value;

  CouponMetaData({this.id, this.key, this.value});

  CouponMetaData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    key = json['key'];
    final rawVal = json['value'];
    if (rawVal is Map<String, dynamic>) {
      value = CouponValue.fromJson(rawVal);
    } else {
      value = rawVal;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['key'] = key;
    if (value is CouponValue) {
      data['value'] = (value as CouponValue).toJson();
    } else {
      data['value'] = value;
    }
    return data;
  }
}

typedef MetaData = CouponMetaData;

class CouponValue {
  String? address;
  String? type;
  CouponValues? values;
  String? condition;

  CouponValue({this.address, this.type, this.values, this.condition});

  CouponValue.fromJson(Map<String, dynamic> json) {
    address = json['address'];
    type = json['type'];
    values = json['values'] is Map<String, dynamic>
        ? CouponValues.fromJson(json['values'] as Map<String, dynamic>)
        : null;
    condition = json['condition'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['address'] = address;
    data['type'] = type;
    if (values != null) {
      data['values'] = values!.toJson();
    }
    data['condition'] = condition;
    return data;
  }
}

typedef Value = CouponValue;

class CouponValues {
  CouponCart? cart;
  List<dynamic>? product;
  List<dynamic>? productCategory;

  CouponValues({this.cart, this.product, this.productCategory});

  CouponValues.fromJson(Map<String, dynamic> json) {
    cart = json['cart'] is Map<String, dynamic>
        ? CouponCart.fromJson(json['cart'] as Map<String, dynamic>)
        : null;
    if (json['product'] != null) {
      product = List<dynamic>.from(json['product']);
    }
    if (json['product_category'] != null) {
      productCategory = List<dynamic>.from(json['product_category']);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (cart != null) {
      data['cart'] = cart!.toJson();
    }
    if (product != null) {
      data['product'] = product;
    }
    if (productCategory != null) {
      data['product_category'] = productCategory;
    }
    return data;
  }
}

typedef Values = CouponValues;

class CouponCart {
  String? min;
  String? max;

  CouponCart({this.min, this.max});

  CouponCart.fromJson(Map<String, dynamic> json) {
    min = json['min']?.toString();
    max = json['max']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['min'] = min;
    data['max'] = max;
    return data;
  }
}

typedef Cart = CouponCart;

class CouponLinks {
  List<CouponSelf>? self;
  List<CouponCollection>? collection;

  CouponLinks({this.self, this.collection});

  CouponLinks.fromJson(Map<String, dynamic> json) {
    if (json['self'] != null) {
      self = <CouponSelf>[];
      for (final v in json['self']) {
        if (v is Map<String, dynamic>) {
          self!.add(CouponSelf.fromJson(v));
        }
      }
    }
    if (json['collection'] != null) {
      collection = <CouponCollection>[];
      for (final v in json['collection']) {
        if (v is Map<String, dynamic>) {
          collection!.add(CouponCollection.fromJson(v));
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
    return data;
  }
}

typedef Links = CouponLinks;

class CouponSelf {
  String? href;
  CouponTargetHints? targetHints;

  CouponSelf({this.href, this.targetHints});

  CouponSelf.fromJson(Map<String, dynamic> json) {
    href = json['href'];
    targetHints = json['targetHints'] != null
        ? CouponTargetHints.fromJson(
            json['targetHints'] as Map<String, dynamic>)
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

typedef Self = CouponSelf;

class CouponTargetHints {
  List<String>? allow;

  CouponTargetHints({this.allow});

  CouponTargetHints.fromJson(Map<String, dynamic> json) {
    if (json['allow'] != null) {
      allow = List<String>.from(json['allow'].map((e) => e.toString()));
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['allow'] = allow;
    return data;
  }
}

typedef TargetHints = CouponTargetHints;

class CouponCollection {
  String? href;

  CouponCollection({this.href});

  CouponCollection.fromJson(Map<String, dynamic> json) {
    href = json['href'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['href'] = href;
    return data;
  }
}

typedef Collection = CouponCollection;
