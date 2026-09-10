import 'dart:convert';

List<GetPaymentGatewaysModel> getPaymentGatewaysModelFromJson(String str) =>
    List<GetPaymentGatewaysModel>.from(
      json.decode(str).map((x) => GetPaymentGatewaysModel.fromJson(x)),
    );

String getPaymentGatewaysModelToJson(List<GetPaymentGatewaysModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetPaymentGatewaysModel {
  String? id;
  String? title;
  String? description;
  int? order;
  bool? enabled;
  String? methodTitle;
  String? methodDescription;
  List<String>? methodSupports;
  Map<String, GatewaySetting>? settings;
  bool? needsSetup;
  List<String>? postInstallScripts;
  String? settingsUrl;
  String? connectionUrl;
  String? setupHelpText;
  List<String>? requiredSettingsKeys;
  Links? lLinks;

  GetPaymentGatewaysModel({
    this.id,
    this.title,
    this.description,
    this.order,
    this.enabled,
    this.methodTitle,
    this.methodDescription,
    this.methodSupports,
    this.settings,
    this.needsSetup,
    this.postInstallScripts,
    this.settingsUrl,
    this.connectionUrl,
    this.setupHelpText,
    this.requiredSettingsKeys,
    this.lLinks,
  });

  GetPaymentGatewaysModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    order = json['order'];
    enabled = json['enabled'];
    methodTitle = json['method_title'];
    methodDescription = json['method_description'];

    if (json['method_supports'] != null) {
      methodSupports = List<String>.from(json['method_supports']);
    }

    if (json['settings'] != null && json['settings'] is Map) {
      settings = (json['settings'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          GatewaySetting.fromJson(value as Map<String, dynamic>),
        ),
      );
    }

    needsSetup = json['needs_setup'];

    if (json['post_install_scripts'] != null) {
      postInstallScripts = List<String>.from(json['post_install_scripts']);
    }

    settingsUrl = json['settings_url'];
    connectionUrl = json['connection_url'];
    setupHelpText = json['setup_help_text'];

    if (json['required_settings_keys'] != null) {
      requiredSettingsKeys =
          List<String>.from(json['required_settings_keys']);
    }

    lLinks = json['_links'] != null ? Links.fromJson(json['_links']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['description'] = description;
    data['order'] = order;
    data['enabled'] = enabled;
    data['method_title'] = methodTitle;
    data['method_description'] = methodDescription;
    if (methodSupports != null) {
      data['method_supports'] = methodSupports;
    }
    if (settings != null) {
      data['settings'] = settings!.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
    }
    data['needs_setup'] = needsSetup;
    if (postInstallScripts != null) {
      data['post_install_scripts'] = postInstallScripts;
    }
    data['settings_url'] = settingsUrl;
    data['connection_url'] = connectionUrl;
    data['setup_help_text'] = setupHelpText;
    if (requiredSettingsKeys != null) {
      data['required_settings_keys'] = requiredSettingsKeys;
    }
    if (lLinks != null) {
      data['_links'] = lLinks!.toJson();
    }
    return data;
  }

  /// Clean display title with sensible fallbacks
  String get displayTitle => (title != null && title!.trim().isNotEmpty)
      ? title!.trim()
      : ((methodTitle != null && methodTitle!.trim().isNotEmpty)
          ? methodTitle!.trim()
          : (id ?? 'Payment Gateway'));

  /// Clean display description fallback
  String get displayDescription =>
      (description != null && description!.trim().isNotEmpty)
          ? description!.trim()
          : ((methodDescription != null && methodDescription!.trim().isNotEmpty)
              ? methodDescription!.trim()
              : 'No gateway description provided.');

  /// Method title display fallback
  String get displayMethodTitle =>
      (methodTitle != null && methodTitle!.trim().isNotEmpty)
          ? methodTitle!.trim()
          : (title ?? '');

  /// Formatted identifier display e.g. `#bacs` or `#cod`
  String get formattedId => id != null ? '#$id' : '#--';

  /// Whether this gateway is actively enabled
  bool get isEnabled => enabled == true;

  /// Whether this gateway needs additional setup
  bool get requiresSetup => needsSetup == true;

  /// Returns sorted list of settings
  List<GatewaySetting> get settingsList => settings?.values.toList() ?? [];

  GetPaymentGatewaysModel copyWith({
    String? id,
    String? title,
    String? description,
    int? order,
    bool? enabled,
    String? methodTitle,
    String? methodDescription,
    List<String>? methodSupports,
    Map<String, GatewaySetting>? settings,
    bool? needsSetup,
    List<String>? postInstallScripts,
    String? settingsUrl,
    String? connectionUrl,
    String? setupHelpText,
    List<String>? requiredSettingsKeys,
    Links? lLinks,
  }) {
    return GetPaymentGatewaysModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      order: order ?? this.order,
      enabled: enabled ?? this.enabled,
      methodTitle: methodTitle ?? this.methodTitle,
      methodDescription: methodDescription ?? this.methodDescription,
      methodSupports: methodSupports ?? this.methodSupports,
      settings: settings ?? this.settings,
      needsSetup: needsSetup ?? this.needsSetup,
      postInstallScripts: postInstallScripts ?? this.postInstallScripts,
      settingsUrl: settingsUrl ?? this.settingsUrl,
      connectionUrl: connectionUrl ?? this.connectionUrl,
      setupHelpText: setupHelpText ?? this.setupHelpText,
      requiredSettingsKeys:
          requiredSettingsKeys ?? this.requiredSettingsKeys,
      lLinks: lLinks ?? this.lLinks,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GetPaymentGatewaysModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          order == other.order &&
          enabled == other.enabled &&
          methodTitle == other.methodTitle &&
          needsSetup == other.needsSetup;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      order.hashCode ^
      enabled.hashCode ^
      methodTitle.hashCode ^
      needsSetup.hashCode;
}

class GatewaySetting {
  String? id;
  String? label;
  String? description;
  String? type;
  String? value;
  String? defaultValue;
  String? tip;
  String? placeholder;

  GatewaySetting({
    this.id,
    this.label,
    this.description,
    this.type,
    this.value,
    this.defaultValue,
    this.tip,
    this.placeholder,
  });

  GatewaySetting.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    label = json['label'];
    description = json['description'];
    type = json['type'];
    value = json['value']?.toString();
    defaultValue = json['default']?.toString();
    tip = json['tip'];
    placeholder = json['placeholder'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['label'] = label;
    data['description'] = description;
    data['type'] = type;
    data['value'] = value;
    data['default'] = defaultValue;
    data['tip'] = tip;
    data['placeholder'] = placeholder;
    return data;
  }

  /// Clean setting label fallback
  String get displayLabel => (label != null && label!.trim().isNotEmpty)
      ? label!.trim()
      : (id ?? 'Setting');

  /// Clean setting value fallback
  String get displayValue => (value != null && value!.trim().isNotEmpty)
      ? value!.trim()
      : (defaultValue != null && defaultValue!.trim().isNotEmpty
          ? defaultValue!.trim()
          : '--');

  GatewaySetting copyWith({
    String? id,
    String? label,
    String? description,
    String? type,
    String? value,
    String? defaultValue,
    String? tip,
    String? placeholder,
  }) {
    return GatewaySetting(
      id: id ?? this.id,
      label: label ?? this.label,
      description: description ?? this.description,
      type: type ?? this.type,
      value: value ?? this.value,
      defaultValue: defaultValue ?? this.defaultValue,
      tip: tip ?? this.tip,
      placeholder: placeholder ?? this.placeholder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GatewaySetting &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          type == other.type &&
          value == other.value;

  @override
  int get hashCode =>
      id.hashCode ^ label.hashCode ^ type.hashCode ^ value.hashCode;
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
