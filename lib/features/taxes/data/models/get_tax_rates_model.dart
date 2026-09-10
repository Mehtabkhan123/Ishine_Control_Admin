import 'dart:convert';

List<GetTaxRatesModel> getTaxRatesModelFromJson(String str) =>
    List<GetTaxRatesModel>.from(
      json.decode(str).map((x) => GetTaxRatesModel.fromJson(x)),
    );

String getTaxRatesModelToJson(List<GetTaxRatesModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetTaxRatesModel {
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
  String? taxClass; // Renamed from 'class' to avoid Dart reserved keyword error
  List<String>? postcodes;
  List<String>? cities;
  Links? lLinks;

  GetTaxRatesModel({
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

  GetTaxRatesModel.fromJson(Map<String, dynamic> json) {
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
    taxClass = json['class']; // Maps JSON key 'class' to taxClass
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

  /// Formatted rate ID badge (e.g. `#14`)
  String get formattedId => id != null ? '#$id' : '#--';

  /// Clean display name fallback
  String get displayName => (name != null && name!.trim().isNotEmpty)
      ? name!.trim()
      : 'Unnamed Tax Rate';

  /// Formatted percentage rate (e.g. `20.00%`)
  String get formattedRate {
    if (rate == null || rate!.isEmpty) return '0%';
    final numVal = double.tryParse(rate!);
    if (numVal != null) {
      // If it's an integer value, show clean number, otherwise up to 4 decimals
      if (numVal == numVal.roundToDouble()) {
        return '${numVal.toInt()}%';
      }
      return '${numVal.toStringAsFixed(2)}%';
    }
    return '$rate%';
  }

  /// Formatted location string (Country, State, City, Postcode)
  String get locationSummary {
    final parts = <String>[];
    if (country != null && country!.trim().isNotEmpty && country != '*') {
      parts.add(country!.trim().toUpperCase());
    } else {
      parts.add('All Countries (*)');
    }

    if (state != null && state!.trim().isNotEmpty && state != '*') {
      parts.add(state!.trim());
    }

    if (city != null && city!.trim().isNotEmpty && city != '*') {
      parts.add(city!.trim());
    }

    if (postcode != null && postcode!.trim().isNotEmpty && postcode != '*') {
      parts.add(postcode!.trim());
    }

    return parts.join(' • ');
  }

  /// Tax class human display name
  String get taxClassDisplay {
    if (taxClass == null || taxClass!.isEmpty || taxClass!.toLowerCase() == 'standard') {
      return 'Standard';
    }
    return taxClass!;
  }

  /// Priority display
  String get priorityDisplay => priority != null ? '$priority' : '1';

  GetTaxRatesModel copyWith({
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
    return GetTaxRatesModel(
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
      other is GetTaxRatesModel &&
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
