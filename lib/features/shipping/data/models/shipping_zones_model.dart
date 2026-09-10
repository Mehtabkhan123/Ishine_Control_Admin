class ShippingZonesModel {
  int? id;
  String? name;
  int? order;
  Links? lLinks;

  ShippingZonesModel({this.id, this.name, this.order, this.lLinks});

  ShippingZonesModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    order = json['order'];
    lLinks = json['_links'] != null ? Links.fromJson(json['_links']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['order'] = order;
    if (lLinks != null) {
      data['_links'] = lLinks!.toJson();
    }
    return data;
  }

  /// Formatted zone ID display e.g. `#1` or `#0 (Everywhere)`
  String get formattedId => id != null ? '#$id' : '#--';

  /// Clean display name fallback
  String get displayName => (name != null && name!.trim().isNotEmpty)
      ? name!.trim()
      : 'Unnamed Zone';

  /// Formatted sort order display
  String get formattedOrder => order != null ? order.toString() : '0';

  /// Whether this is the default fallback zone (id == 0)
  bool get isDefaultZone => id == 0;

  ShippingZonesModel copyWith({
    int? id,
    String? name,
    int? order,
    Links? lLinks,
  }) {
    return ShippingZonesModel(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      lLinks: lLinks ?? this.lLinks,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShippingZonesModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          order == other.order;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ order.hashCode;
}

class Links {
  List<Self>? self;
  List<Collection>? collection;
  List<Describedby>? describedby;

  Links({this.self, this.collection, this.describedby});

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
    if (json['describedby'] != null) {
      describedby = <Describedby>[];
      json['describedby'].forEach((v) {
        describedby!.add(Describedby.fromJson(v));
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
    if (describedby != null) {
      data['describedby'] = describedby!.map((v) => v.toJson()).toList();
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
    allow = json['allow']?.cast<String>();
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

class Describedby {
  String? href;

  Describedby({this.href});

  Describedby.fromJson(Map<String, dynamic> json) {
    href = json['href'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['href'] = href;
    return data;
  }
}

/// Alias for compatibility with previous naming
typedef GetShippingClassesModel = ShippingZonesModel;
