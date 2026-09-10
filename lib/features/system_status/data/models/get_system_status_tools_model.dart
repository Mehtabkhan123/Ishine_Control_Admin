import 'dart:convert';

List<GetSystemStatusToolsModel> getSystemStatusToolsModelFromJson(String str) =>
    List<GetSystemStatusToolsModel>.from(
        json.decode(str).map((x) => GetSystemStatusToolsModel.fromJson(x)));

String getSystemStatusToolsModelToJson(List<GetSystemStatusToolsModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetSystemStatusToolsModel {
  String? id;
  String? name;
  String? action;
  String? description;
  Links? lLinks;

  GetSystemStatusToolsModel({
    this.id,
    this.name,
    this.action,
    this.description,
    this.lLinks,
  });

  GetSystemStatusToolsModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    action = json['action'];
    description = json['description'];
    lLinks = json['_links'] != null ? Links.fromJson(json['_links']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['action'] = action;
    data['description'] = description;
    if (lLinks != null) {
      data['_links'] = lLinks!.toJson();
    }
    return data;
  }

  /// Convenience copyWith method
  GetSystemStatusToolsModel copyWith({
    String? id,
    String? name,
    String? action,
    String? description,
    Links? lLinks,
  }) {
    return GetSystemStatusToolsModel(
      id: id ?? this.id,
      name: name ?? this.name,
      action: action ?? this.action,
      description: description ?? this.description,
      lLinks: lLinks ?? this.lLinks,
    );
  }

  /// Readable human display name
  String get displayName =>
      (name != null && name!.trim().isNotEmpty) ? name!.trim() : (id ?? 'System Tool');

  /// Readable description
  String get displayDescription =>
      (description != null && description!.trim().isNotEmpty)
          ? description!.trim()
          : 'No description provided.';

  /// Formatted action label
  String get displayAction =>
      (action != null && action!.trim().isNotEmpty)
          ? action!.trim()
          : 'Run Tool';

  /// Whether this tool has an executable action
  bool get hasAction => action != null && action!.trim().isNotEmpty;

  /// Convenience getter for `lLinks`
  Links? get links => lLinks;

  /// Retrieves first item href if available
  String get firstHref {
    if (lLinks?.item != null && lLinks!.item!.isNotEmpty) {
      return lLinks!.item!.first.href ?? '';
    }
    return '';
  }

  /// Whether the tool endpoint is embeddable
  bool get isEmbeddable {
    if (lLinks?.item != null && lLinks!.item!.isNotEmpty) {
      return lLinks!.item!.first.embeddable == true;
    }
    return false;
  }
}

class Links {
  List<Item>? item;

  Links({this.item});

  Links.fromJson(Map<String, dynamic> json) {
    if (json['item'] != null) {
      item = <Item>[];
      json['item'].forEach((v) {
        item!.add(Item.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (item != null) {
      data['item'] = item!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Item {
  bool? embeddable;
  String? href;

  Item({this.embeddable, this.href});

  Item.fromJson(Map<String, dynamic> json) {
    embeddable = json['embeddable'];
    href = json['href'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['embeddable'] = embeddable;
    data['href'] = href;
    return data;
  }
}
