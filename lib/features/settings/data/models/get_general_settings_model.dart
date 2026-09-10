import 'dart:convert';

List<GetGeneralSettingsModel> getGeneralSettingsModelFromJson(String str) =>
    List<GetGeneralSettingsModel>.from(
        json.decode(str).map((x) => GetGeneralSettingsModel.fromJson(x)));

String getGeneralSettingsModelToJson(List<GetGeneralSettingsModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetGeneralSettingsModel {
  String? id;
  String? label;
  String? description;
  String? type;
  dynamic defaultValue; // Renamed from 'default' to avoid reserved keyword
  String? tip;
  dynamic value;
  Map<String, String>? options;
  Links? lLinks;

  GetGeneralSettingsModel({
    this.id,
    this.label,
    this.description,
    this.type,
    this.defaultValue,
    this.tip,
    this.value,
    this.options,
    this.lLinks,
  });

  GetGeneralSettingsModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    label = json['label'];
    description = json['description'];
    type = json['type'];
    defaultValue = json['default']; // Maps from JSON 'default'
    tip = json['tip'];
    value = json['value'];

    if (json['options'] != null && json['options'] is Map) {
      options = (json['options'] as Map).map(
        (key, val) => MapEntry(key.toString(), val.toString()),
      );
    }

    lLinks = json['_links'] != null ? Links.fromJson(json['_links']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['label'] = label;
    data['description'] = description;
    data['type'] = type;
    data['default'] = defaultValue; // Maps to JSON 'default'
    data['tip'] = tip;
    data['value'] = value;
    if (options != null) {
      data['options'] = options;
    }
    if (lLinks != null) {
      data['_links'] = lLinks!.toJson();
    }
    return data;
  }

  /// Convenience copyWith method for state updates
  GetGeneralSettingsModel copyWith({
    String? id,
    String? label,
    String? description,
    String? type,
    dynamic defaultValue,
    String? tip,
    dynamic value,
    Map<String, String>? options,
    Links? lLinks,
  }) {
    return GetGeneralSettingsModel(
      id: id ?? this.id,
      label: label ?? this.label,
      description: description ?? this.description,
      type: type ?? this.type,
      defaultValue: defaultValue ?? this.defaultValue,
      tip: tip ?? this.tip,
      value: value ?? this.value,
      options: options ?? this.options,
      lLinks: lLinks ?? this.lLinks,
    );
  }

  /// Readable human label fallback
  String get displayLabel =>
      (label != null && label!.trim().isNotEmpty) ? label!.trim() : (id ?? 'Setting');

  /// Readable description with fallback to tip
  String get displayDescription =>
      (description != null && description!.trim().isNotEmpty)
          ? description!.trim()
          : (tip?.trim() ?? '');

  /// Safe string representation of the dynamic value
  String get stringValue => value != null ? value.toString() : '';

  /// Safe string representation of the dynamic defaultValue
  String get stringDefaultValue => defaultValue != null ? defaultValue.toString() : '';

  /// Determines whether this is a boolean checkbox setting
  bool get isCheckbox => type?.toLowerCase() == 'checkbox';

  /// Determines whether this is a single select setting
  bool get isSelect => type?.toLowerCase() == 'select';

  /// Determines whether this is a multiselect setting
  bool get isMultiselect => type?.toLowerCase() == 'multiselect';

  /// Determines whether this is a numeric setting
  bool get isNumber =>
      type?.toLowerCase() == 'number' || type?.toLowerCase() == 'integer';

  /// Evaluates boolean truthiness for checkbox settings
  bool get boolValue =>
      value == true ||
      value == 'yes' ||
      value == '1' ||
      value == 1 ||
      value == 'true';

  /// Evaluates default boolean truthiness for checkbox settings
  bool get defaultBoolValue =>
      defaultValue == true ||
      defaultValue == 'yes' ||
      defaultValue == '1' ||
      defaultValue == 1 ||
      defaultValue == 'true';

  /// Formatted option label if this is a select setting with an options dictionary
  String get displayOptionLabel {
    if (isSelect && options != null && options!.containsKey(stringValue)) {
      return options![stringValue]!;
    }
    return stringValue;
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
    if (allow != null) {
      data['allow'] = allow;
    }
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
