import 'dart:convert';

PostTaxRatesModel postTaxRatesModelFromJson(String str) =>
    PostTaxRatesModel.fromJson(json.decode(str));

String postTaxRatesModelToJson(PostTaxRatesModel data) =>
    json.encode(data.toJson());

class PostTaxRatesModel {
  int? id;
  String? country;
  String? state;
  String? postcode;
  String? city;
  String? rate;
  String? name;
  int? priority;
  bool? compound;
  bool? shipping;
  int? order;
  String? taxClass; // Renamed from 'class' (Dart reserved keyword)
  List<String>? postcodes;
  List<String>? cities;
  Links? lLinks;

  PostTaxRatesModel({
    this.id,
    this.country,
    this.state,
    this.postcode,
    this.city,
    this.rate,
    this.name,
    this.priority,
    this.compound,
    this.shipping,
    this.order,
    this.taxClass,
    this.postcodes,
    this.cities,
    this.lLinks,
  });

  PostTaxRatesModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    country = json['country'];
    state = json['state'];
    postcode = json['postcode'];
    city = json['city'];
    rate = json['rate'];
    name = json['name'];
    priority = json['priority'];
    compound = json['compound'];
    shipping = json['shipping'];
    order = json['order'];
    taxClass = json['class']; // Maps JSON 'class' to taxClass
    if (json['postcodes'] != null) {
      postcodes = List<String>.from(json['postcodes']);
    }
    if (json['cities'] != null) {
      cities = List<String>.from(json['cities']);
    }
    lLinks = json['_links'] != null ? Links.fromJson(json['_links']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['country'] = country;
    data['state'] = state;
    data['postcode'] = postcode;
    data['city'] = city;
    data['rate'] = rate;
    data['name'] = name;
    data['priority'] = priority;
    data['compound'] = compound;
    data['shipping'] = shipping;
    data['order'] = order;
    data['class'] = taxClass; // Maps taxClass back to JSON key 'class'
    if (postcodes != null) {
      data['postcodes'] = postcodes;
    }
    if (cities != null) {
      data['cities'] = cities;
    }
    if (lLinks != null) {
      data['_links'] = lLinks!.toJson();
    }
    return data;
  }

  /// Exports only writable fields required for POST /wp-json/wc/v3/taxes creation.
  /// Excludes read-only fields like `id` and `_links`.
  Map<String, dynamic> toCreateJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (country != null && country!.isNotEmpty) data['country'] = country;
    if (state != null && state!.isNotEmpty) data['state'] = state;
    if (postcode != null && postcode!.isNotEmpty) data['postcode'] = postcode;
    if (city != null && city!.isNotEmpty) data['city'] = city;
    if (rate != null && rate!.isNotEmpty) data['rate'] = rate;
    if (name != null && name!.isNotEmpty) data['name'] = name;
    if (priority != null) data['priority'] = priority;
    if (compound != null) data['compound'] = compound;
    if (shipping != null) data['shipping'] = shipping;
    if (order != null) data['order'] = order;
    if (taxClass != null && taxClass!.isNotEmpty) data['class'] = taxClass;
    if (postcodes != null && postcodes!.isNotEmpty) data['postcodes'] = postcodes;
    if (cities != null && cities!.isNotEmpty) data['cities'] = cities;
    return data;
  }

  PostTaxRatesModel copyWith({
    int? id,
    String? country,
    String? state,
    String? postcode,
    String? city,
    String? rate,
    String? name,
    int? priority,
    bool? compound,
    bool? shipping,
    int? order,
    String? taxClass,
    List<String>? postcodes,
    List<String>? cities,
    Links? lLinks,
  }) {
    return PostTaxRatesModel(
      id: id ?? this.id,
      country: country ?? this.country,
      state: state ?? this.state,
      postcode: postcode ?? this.postcode,
      city: city ?? this.city,
      rate: rate ?? this.rate,
      name: name ?? this.name,
      priority: priority ?? this.priority,
      compound: compound ?? this.compound,
      shipping: shipping ?? this.shipping,
      order: order ?? this.order,
      taxClass: taxClass ?? this.taxClass,
      postcodes: postcodes ?? this.postcodes,
      cities: cities ?? this.cities,
      lLinks: lLinks ?? this.lLinks,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostTaxRatesModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          country == other.country &&
          state == other.state &&
          postcode == other.postcode &&
          city == other.city &&
          rate == other.rate &&
          name == other.name &&
          priority == other.priority &&
          compound == other.compound &&
          shipping == other.shipping &&
          order == other.order &&
          taxClass == other.taxClass;

  @override
  int get hashCode =>
      id.hashCode ^
      country.hashCode ^
      state.hashCode ^
      postcode.hashCode ^
      city.hashCode ^
      rate.hashCode ^
      name.hashCode ^
      priority.hashCode ^
      compound.hashCode ^
      shipping.hashCode ^
      order.hashCode ^
      taxClass.hashCode;
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
    if (json['allow'] != null) {
      allow = json['allow'].cast<String>();
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
    href = json['href'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['href'] = href;
    return data;
  }
}
