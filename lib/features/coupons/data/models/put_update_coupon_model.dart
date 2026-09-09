import 'get_coupon_report_model.dart';

class PutUpdateCouponModel {
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
  List<dynamic>? usedBy;
  List<dynamic>? metaData;
  Links? lLinks;

  PutUpdateCouponModel({
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

  PutUpdateCouponModel.fromJson(Map<String, dynamic> json) {
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
    dateExpires = json['date_expires']?.toString();
    dateExpiresGmt = json['date_expires_gmt']?.toString();
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
      usedBy = List<dynamic>.from(json['used_by']);
    }
    if (json['meta_data'] != null) {
      metaData = List<dynamic>.from(json['meta_data']);
    }
    lLinks = json['_links'] != null ? Links.fromJson(json['_links']) : null;
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
    if (usedBy != null) {
      data['used_by'] = usedBy;
    }
    if (metaData != null) {
      data['meta_data'] = metaData;
    }
    if (lLinks != null) {
      data['_links'] = lLinks!.toJson();
    }
    return data;
  }

  /// Converts this updated coupon model to a [GETCouponReportModel]
  /// for seamless local state synchronisation.
  GETCouponReportModel toCouponReportModel() {
    return GETCouponReportModel.fromJson(toJson());
  }

  /// Helper to build strictly valid writable WooCommerce fields for PUT update:
  /// `PUT /wp-json/wc/v3/coupons/{{couponId}}`
  ///
  /// Response-only fields such as `id`, `date_created`, `date_modified`,
  /// `usage_count`, `used_by`, and `_links` are strictly excluded.
  static Map<String, dynamic> toUpdatePayload({
    String? code,
    String? amount,
    String? discountType,
    String? description,
    String? dateExpires,
    bool? individualUse,
    bool? freeShipping,
    bool? excludeSaleItems,
    String? minimumAmount,
    String? maximumAmount,
    List<int>? productIds,
    List<int>? excludedProductIds,
    List<int>? productCategories,
    List<int>? excludedProductCategories,
    List<String>? emailRestrictions,
    int? usageLimit,
    int? usageLimitPerUser,
    int? limitUsageToXItems,
  }) {
    final Map<String, dynamic> payload = {};

    if (code != null && code.trim().isNotEmpty) {
      payload['code'] = code.trim();
    }
    if (amount != null && amount.trim().isNotEmpty) {
      payload['amount'] = amount.trim();
    }
    if (discountType != null && discountType.trim().isNotEmpty) {
      payload['discount_type'] = discountType.trim();
    }
    if (description != null) {
      payload['description'] = description.trim();
    }
    if (dateExpires != null) {
      payload['date_expires'] = dateExpires.trim();
    }
    if (individualUse != null) {
      payload['individual_use'] = individualUse;
    }
    if (freeShipping != null) {
      payload['free_shipping'] = freeShipping;
    }
    if (excludeSaleItems != null) {
      payload['exclude_sale_items'] = excludeSaleItems;
    }
    if (minimumAmount != null) {
      payload['minimum_amount'] = minimumAmount.trim();
    }
    if (maximumAmount != null) {
      payload['maximum_amount'] = maximumAmount.trim();
    }
    if (productIds != null) {
      payload['product_ids'] = productIds;
    }
    if (excludedProductIds != null) {
      payload['excluded_product_ids'] = excludedProductIds;
    }
    if (productCategories != null) {
      payload['product_categories'] = productCategories;
    }
    if (excludedProductCategories != null) {
      payload['excluded_product_categories'] = excludedProductCategories;
    }
    if (emailRestrictions != null) {
      payload['email_restrictions'] = emailRestrictions;
    }
    if (usageLimit != null) {
      payload['usage_limit'] = usageLimit > 0 ? usageLimit : null;
    }
    if (usageLimitPerUser != null) {
      payload['usage_limit_per_user'] =
          usageLimitPerUser > 0 ? usageLimitPerUser : null;
    }
    if (limitUsageToXItems != null) {
      payload['limit_usage_to_x_items'] =
          limitUsageToXItems > 0 ? limitUsageToXItems : null;
    }

    return payload;
  }
}

class Links {
  List<Self>? self;
  List<Collection>? collection;

  Links({this.self, this.collection});

  Links.fromJson(Map<String, dynamic> json) {
    if (json['self'] != null) {
      self = <Self>[];
      json['self'].forEach((v) {
        self!.add(Self.fromJson(v));
      });
    }
    if (json['collection'] != null) {
      collection = <Collection>[];
      json['collection'].forEach((v) {
        collection!.add(Collection.fromJson(v));
      });
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
    href = json['href'];
    targetHints = json['targetHints'] != null
        ? TargetHints.fromJson(json['targetHints'])
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
    allow = json['allow'] != null ? List<String>.from(json['allow']) : null;
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
    href = json['href'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['href'] = href;
    return data;
  }
}
