import 'dart:convert';
import 'get_payment_gateways_model.dart' as get_model;

PutUpdatePaymentGatewaysModel putUpdatePaymentGatewaysModelFromJson(
        String str) =>
    PutUpdatePaymentGatewaysModel.fromJson(json.decode(str));

String putUpdatePaymentGatewaysModelToJson(
        PutUpdatePaymentGatewaysModel data) =>
    json.encode(data.toJson());

class PutUpdatePaymentGatewaysModel {
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

  PutUpdatePaymentGatewaysModel({
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

  PutUpdatePaymentGatewaysModel.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    title = json['title']?.toString();
    description = json['description']?.toString();
    if (json['order'] != null) {
      order = int.tryParse(json['order'].toString()) ?? json['order'];
    }
    if (json['enabled'] != null) {
      if (json['enabled'] is bool) {
        enabled = json['enabled'];
      } else if (json['enabled'] is String) {
        enabled = json['enabled'] == 'yes' ||
            json['enabled'] == 'true' ||
            json['enabled'] == '1';
      }
    }
    methodTitle = json['method_title']?.toString();
    methodDescription = json['method_description']?.toString();

    if (json['method_supports'] != null) {
      methodSupports = List<String>.from(json['method_supports']);
    }

    if (json['settings'] != null && json['settings'] is Map) {
      settings = (json['settings'] as Map<String, dynamic>).map(
        (key, value) {
          if (value is Map<String, dynamic>) {
            return MapEntry(key, GatewaySetting.fromJson(value));
          } else if (value is Map) {
            return MapEntry(
              key,
              GatewaySetting.fromJson(Map<String, dynamic>.from(value)),
            );
          } else {
            return MapEntry(
              key,
              GatewaySetting(id: key, value: value?.toString()),
            );
          }
        },
      );
    }

    if (json['needs_setup'] != null) {
      needsSetup = json['needs_setup'] is bool
          ? json['needs_setup']
          : (json['needs_setup'].toString() == 'true');
    }

    if (json['post_install_scripts'] != null) {
      postInstallScripts = List<String>.from(json['post_install_scripts']);
    }

    settingsUrl = json['settings_url']?.toString();
    connectionUrl = json['connection_url']?.toString();
    setupHelpText = json['setup_help_text']?.toString();

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

  /// Extracts only valid writable fields for WooCommerce PUT update request:
  /// `PUT /wp-json/wc/v3/payment_gateways/{{paymentGatewayId}}`
  ///
  /// Strictly omits read-only fields such as `id`, `method_title`, `method_supports`,
  /// `needs_setup`, `post_install_scripts`, `settings_url`, `connection_url`,
  /// `setup_help_text`, `required_settings_keys`, and `_links`.
  Map<String, dynamic> toUpdatePayload() {
    final Map<String, dynamic> payload = {};

    if (title != null) {
      payload['title'] = title;
    }
    if (description != null) {
      payload['description'] = description;
    }
    if (order != null) {
      payload['order'] = order;
    }
    if (enabled != null) {
      payload['enabled'] = enabled;
    }
    if (settings != null && settings!.isNotEmpty) {
      final Map<String, dynamic> settingsMap = {};
      settings!.forEach((key, setting) {
        if (setting.value != null) {
          settingsMap[key] = setting.value;
        }
      });
      payload['settings'] = settingsMap;
    }

    return payload;
  }

  /// Static helper to build a strictly writable payload map from arguments.
  static Map<String, dynamic> toUpdatePayloadMap({
    String? title,
    String? description,
    int? order,
    bool? enabled,
    Map<String, dynamic>? settings,
  }) {
    final Map<String, dynamic> payload = {};

    if (title != null) {
      payload['title'] = title.trim();
    }
    if (description != null) {
      payload['description'] = description.trim();
    }
    if (order != null) {
      payload['order'] = order;
    }
    if (enabled != null) {
      payload['enabled'] = enabled;
    }
    if (settings != null && settings.isNotEmpty) {
      payload['settings'] = settings;
    }

    return payload;
  }

  /// Converts this update model into [get_model.GetPaymentGatewaysModel] to update local bloc cache.
  get_model.GetPaymentGatewaysModel toGetPaymentGatewaysModel() {
    return get_model.GetPaymentGatewaysModel(
      id: id,
      title: title,
      description: description,
      order: order,
      enabled: enabled,
      methodTitle: methodTitle,
      methodDescription: methodDescription,
      methodSupports: methodSupports,
      settings: settings?.map(
        (k, v) => MapEntry(
          k,
          get_model.GatewaySetting(
            id: v.id,
            label: v.label,
            description: v.description,
            type: v.type,
            value: v.value,
            defaultValue: v.defaultValue,
            tip: v.tip,
            placeholder: v.placeholder,
          ),
        ),
      ),
      needsSetup: needsSetup,
      postInstallScripts: postInstallScripts,
      settingsUrl: settingsUrl,
      connectionUrl: connectionUrl,
      setupHelpText: setupHelpText,
      requiredSettingsKeys: requiredSettingsKeys,
    );
  }

  PutUpdatePaymentGatewaysModel copyWith({
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
    return PutUpdatePaymentGatewaysModel(
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
      other is PutUpdatePaymentGatewaysModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          order == other.order &&
          enabled == other.enabled &&
          methodTitle == other.methodTitle;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      order.hashCode ^
      enabled.hashCode ^
      methodTitle.hashCode;
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
    id = json['id']?.toString();
    label = json['label']?.toString();
    description = json['description']?.toString();
    type = json['type']?.toString();
    value = json['value']?.toString();
    defaultValue = json['default']?.toString();
    tip = json['tip']?.toString();
    placeholder = json['placeholder']?.toString();
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
