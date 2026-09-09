import 'get_customers_model.dart';
export 'get_customers_model.dart' show Billing, Shipping, MetaData, Links, Self, TargetHints, Collection;

/// Model for parsing complete single customer response from WooCommerce API:
/// `GET {{baseUrl}}/wp-json/wc/v3/customers/{{customerId}}`
class GETSingleCustomersModel {
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

  GETSingleCustomersModel({
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

  /// Creates a [GETSingleCustomersModel] from a [GETCustomersModel] list item
  factory GETSingleCustomersModel.fromCustomersModel(GETCustomersModel customer) {
    return GETSingleCustomersModel(
      id: customer.id,
      dateCreated: customer.dateCreated,
      dateCreatedGmt: customer.dateCreatedGmt,
      dateModified: customer.dateModified,
      dateModifiedGmt: customer.dateModifiedGmt,
      email: customer.email,
      firstName: customer.firstName,
      lastName: customer.lastName,
      role: customer.role,
      username: customer.username,
      billing: customer.billing,
      shipping: customer.shipping,
      isPayingCustomer: customer.isPayingCustomer,
      avatarUrl: customer.avatarUrl,
      metaData: customer.metaData,
      lLinks: customer.lLinks,
    );
  }

  GETSingleCustomersModel.fromJson(Map<String, dynamic> json) {
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
