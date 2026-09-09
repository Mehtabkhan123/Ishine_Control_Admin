class GETCustomersModel {
  int? id;
  String? dateCreated;
  String? dateCreatedGmt;
  String? dateModified;
  String? dateModifiedGmt;
  String? email;
  String? firstName;
  String? lastName;
  String? role;
  String? username;
  Billing? billing;
  Shipping? shipping;
  bool? isPayingCustomer;
  String? avatarUrl;
  List<MetaData>? metaData;
  Links? lLinks;

  GETCustomersModel({
    this.id,
    this.dateCreated,
    this.dateCreatedGmt,
    this.dateModified,
    this.dateModifiedGmt,
    this.email,
    this.firstName,
    this.lastName,
    this.role,
    this.username,
    this.billing,
    this.shipping,
    this.isPayingCustomer,
    this.avatarUrl,
    this.metaData,
    this.lLinks,
  });

  GETCustomersModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    dateCreated = json['date_created'];
    dateCreatedGmt = json['date_created_gmt'];
    dateModified = json['date_modified'];
    dateModifiedGmt = json['date_modified_gmt'];
    email = json['email'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    role = json['role'];
    username = json['username'];
    billing =
        json['billing'] != null ? Billing.fromJson(json['billing']) : null;
    shipping =
        json['shipping'] != null ? Shipping.fromJson(json['shipping']) : null;
    isPayingCustomer = json['is_paying_customer'];
    avatarUrl = json['avatar_url'];
    if (json['meta_data'] != null) {
      metaData = <MetaData>[];
      json['meta_data'].forEach((v) {
        metaData!.add(MetaData.fromJson(v));
      });
    }
    lLinks = json['_links'] != null ? Links.fromJson(json['_links']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['date_created'] = dateCreated;
    data['date_created_gmt'] = dateCreatedGmt;
    data['date_modified'] = dateModified;
    data['date_modified_gmt'] = dateModifiedGmt;
    data['email'] = email;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['role'] = role;
    data['username'] = username;
    if (billing != null) {
      data['billing'] = billing!.toJson();
    }
    if (shipping != null) {
      data['shipping'] = shipping!.toJson();
    }
    data['is_paying_customer'] = isPayingCustomer;
    data['avatar_url'] = avatarUrl;
    if (metaData != null) {
      data['meta_data'] = metaData!.map((v) => v.toJson()).toList();
    }
    if (lLinks != null) {
      data['_links'] = lLinks!.toJson();
    }
    return data;
  }

  // --- Convenience Getters ---

  /// Full customer display name, with fallback to username or email.
  String get displayName {
    final first = (firstName ?? '').trim();
    final last = (lastName ?? '').trim();
    if (first.isNotEmpty || last.isNotEmpty) {
      return '$first $last'.trim();
    }
    if (billing != null) {
      final bFirst = (billing!.firstName ?? '').trim();
      final bLast = (billing!.lastName ?? '').trim();
      if (bFirst.isNotEmpty || bLast.isNotEmpty) {
        return '$bFirst $bLast'.trim();
      }
    }
    if (username != null && username!.trim().isNotEmpty) {
      return username!.trim();
    }
    if (email != null && email!.trim().isNotEmpty) {
      return email!.trim();
    }
    return 'Customer #${id ?? 0}';
  }

  /// Initials derived from customer's name, username, or email.
  String get initials {
    final name = displayName.trim();
    if (name.isEmpty) return 'C';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  /// Primary phone number from billing or shipping.
  String? get primaryPhone {
    final bPhone = billing?.phone?.trim();
    if (bPhone != null && bPhone.isNotEmpty) return bPhone;
    final sPhone = shipping?.phone?.trim();
    if (sPhone != null && sPhone.isNotEmpty) return sPhone;
    return null;
  }

  /// Location summary string: "City, Country" or "State, Country".
  String get locationSummary {
    final city = billing?.city?.trim() ?? shipping?.city?.trim() ?? '';
    final state = billing?.state?.trim() ?? shipping?.state?.trim() ?? '';
    final country = billing?.country?.trim() ?? shipping?.country?.trim() ?? '';

    final parts = <String>[];
    if (city.isNotEmpty) {
      parts.add(city);
    } else if (state.isNotEmpty) {
      parts.add(state);
    }
    if (country.isNotEmpty) {
      parts.add(country);
    }
    return parts.isNotEmpty ? parts.join(', ') : 'Location not provided';
  }

  /// Safe parsed DateTime from [dateCreated].
  DateTime? get parsedDateCreated {
    if (dateCreated == null || dateCreated!.isEmpty) return null;
    return DateTime.tryParse(dateCreated!);
  }

  /// Safe parsed DateTime from [dateModified].
  DateTime? get parsedDateModified {
    if (dateModified == null || dateModified!.isEmpty) return null;
    return DateTime.tryParse(dateModified!);
  }

  /// Capitalized role name (e.g. "Customer", "Administrator", etc.).
  String get roleDisplayName {
    if (role == null || role!.trim().isEmpty) return 'Customer';
    final r = role!.trim();
    return r[0].toUpperCase() + r.substring(1).toLowerCase();
  }
}

class Billing {
  String? firstName;
  String? lastName;
  String? company;
  String? address1;
  String? address2;
  String? city;
  String? postcode;
  String? country;
  String? state;
  String? email;
  String? phone;

  Billing({
    this.firstName,
    this.lastName,
    this.company,
    this.address1,
    this.address2,
    this.city,
    this.postcode,
    this.country,
    this.state,
    this.email,
    this.phone,
  });

  Billing.fromJson(Map<String, dynamic> json) {
    firstName = json['first_name'];
    lastName = json['last_name'];
    company = json['company'];
    address1 = json['address_1'];
    address2 = json['address_2'];
    city = json['city'];
    postcode = json['postcode'];
    country = json['country'];
    state = json['state'];
    email = json['email'];
    phone = json['phone'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['company'] = company;
    data['address_1'] = address1;
    data['address_2'] = address2;
    data['city'] = city;
    data['postcode'] = postcode;
    data['country'] = country;
    data['state'] = state;
    data['email'] = email;
    data['phone'] = phone;
    return data;
  }

  /// Full formatted billing address.
  String get formattedAddress {
    final lines = <String>[];
    final name = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    if (name.isNotEmpty) lines.add(name);
    if (company != null && company!.trim().isNotEmpty) lines.add(company!.trim());
    if (address1 != null && address1!.trim().isNotEmpty) lines.add(address1!.trim());
    if (address2 != null && address2!.trim().isNotEmpty) lines.add(address2!.trim());
    final cityStateZip = [
      if (city != null && city!.trim().isNotEmpty) city!.trim(),
      if (state != null && state!.trim().isNotEmpty) state!.trim(),
      if (postcode != null && postcode!.trim().isNotEmpty) postcode!.trim(),
    ].join(' ');
    if (cityStateZip.isNotEmpty) lines.add(cityStateZip);
    if (country != null && country!.trim().isNotEmpty) lines.add(country!.trim());
    return lines.join('\n');
  }

  bool get isEmpty {
    return (firstName ?? '').isEmpty &&
        (lastName ?? '').isEmpty &&
        (company ?? '').isEmpty &&
        (address1 ?? '').isEmpty &&
        (city ?? '').isEmpty &&
        (country ?? '').isEmpty &&
        (phone ?? '').isEmpty &&
        (email ?? '').isEmpty;
  }
}

class Shipping {
  String? firstName;
  String? lastName;
  String? company;
  String? address1;
  String? address2;
  String? city;
  String? postcode;
  String? country;
  String? state;
  String? phone;

  Shipping({
    this.firstName,
    this.lastName,
    this.company,
    this.address1,
    this.address2,
    this.city,
    this.postcode,
    this.country,
    this.state,
    this.phone,
  });

  Shipping.fromJson(Map<String, dynamic> json) {
    firstName = json['first_name'];
    lastName = json['last_name'];
    company = json['company'];
    address1 = json['address_1'];
    address2 = json['address_2'];
    city = json['city'];
    postcode = json['postcode'];
    country = json['country'];
    state = json['state'];
    phone = json['phone'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['company'] = company;
    data['address_1'] = address1;
    data['address_2'] = address2;
    data['city'] = city;
    data['postcode'] = postcode;
    data['country'] = country;
    data['state'] = state;
    data['phone'] = phone;
    return data;
  }

  /// Full formatted shipping address.
  String get formattedAddress {
    final lines = <String>[];
    final name = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    if (name.isNotEmpty) lines.add(name);
    if (company != null && company!.trim().isNotEmpty) lines.add(company!.trim());
    if (address1 != null && address1!.trim().isNotEmpty) lines.add(address1!.trim());
    if (address2 != null && address2!.trim().isNotEmpty) lines.add(address2!.trim());
    final cityStateZip = [
      if (city != null && city!.trim().isNotEmpty) city!.trim(),
      if (state != null && state!.trim().isNotEmpty) state!.trim(),
      if (postcode != null && postcode!.trim().isNotEmpty) postcode!.trim(),
    ].join(' ');
    if (cityStateZip.isNotEmpty) lines.add(cityStateZip);
    if (country != null && country!.trim().isNotEmpty) lines.add(country!.trim());
    return lines.join('\n');
  }

  bool get isEmpty {
    return (firstName ?? '').isEmpty &&
        (lastName ?? '').isEmpty &&
        (company ?? '').isEmpty &&
        (address1 ?? '').isEmpty &&
        (city ?? '').isEmpty &&
        (country ?? '').isEmpty &&
        (phone ?? '').isEmpty;
  }
}

class MetaData {
  int? id;
  String? key;
  dynamic value;

  MetaData({this.id, this.key, this.value});

  MetaData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    key = json['key'];
    value = json['value'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['key'] = key;
    data['value'] = value;
    return data;
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
    if (json['allow'] != null) {
      allow = List<String>.from(json['allow']);
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
