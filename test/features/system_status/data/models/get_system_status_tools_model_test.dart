import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/system_status/data/models/get_system_status_tools_model.dart';

void main() {
  group('GetSystemStatusToolsModel', () {
    final sampleJson = {
      'id': 'clear_transients',
      'name': 'WooCommerce transients',
      'action': 'Clear transients',
      'description': 'This tool will clear the WooCommerce transients cache.',
      '_links': {
        'item': [
          {
            'href': 'https://example.com/wp-json/wc/v3/system_status/tools/clear_transients',
            'embeddable': true,
          }
        ]
      }
    };

    final sampleJsonList = [
      sampleJson,
      {
        'id': 'clear_expired_transients',
        'name': 'Expired transients',
        'action': 'Clear expired transients',
        'description': 'This tool will clear expired WooCommerce transients.',
      },
      {
        'id': 'db_check',
        'name': 'Verify database',
        'description': 'No executable action for this diagnostic.',
      }
    ];

    test('fromJson parses full fields correctly', () {
      final model = GetSystemStatusToolsModel.fromJson(sampleJson);

      expect(model.id, 'clear_transients');
      expect(model.name, 'WooCommerce transients');
      expect(model.action, 'Clear transients');
      expect(model.description,
          'This tool will clear the WooCommerce transients cache.');
      expect(model.links?.item?.length, 1);
      expect(model.links?.item?.first.href,
          'https://example.com/wp-json/wc/v3/system_status/tools/clear_transients');
      expect(model.links?.item?.first.embeddable, true);
      expect(model.hasAction, true);
      expect(model.isEmbeddable, true);
      expect(model.firstHref,
          'https://example.com/wp-json/wc/v3/system_status/tools/clear_transients');
      expect(model.displayName, 'WooCommerce transients');
      expect(model.displayAction, 'Clear transients');
    });

    test('toJson serializes model back to valid Map', () {
      final model = GetSystemStatusToolsModel.fromJson(sampleJson);
      final json = model.toJson();

      expect(json['id'], 'clear_transients');
      expect(json['name'], 'WooCommerce transients');
      expect(json['action'], 'Clear transients');
      expect(json['description'],
          'This tool will clear the WooCommerce transients cache.');
      expect(json['_links']['item'][0]['embeddable'], true);
    });

    test('helper getSystemStatusToolsModelFromJson parses list string', () {
      final jsonStr = jsonEncode(sampleJsonList);
      final list = getSystemStatusToolsModelFromJson(jsonStr);

      expect(list.length, 3);
      expect(list[0].id, 'clear_transients');
      expect(list[1].id, 'clear_expired_transients');
      expect(list[2].id, 'db_check');
      expect(list[2].hasAction, false);
      expect(list[2].displayAction, 'Run Tool');
    });

    test('helper getSystemStatusToolsModelToJson serializes list to string', () {
      final list = [
        GetSystemStatusToolsModel.fromJson(sampleJson),
      ];
      final jsonStr = getSystemStatusToolsModelToJson(list);
      expect(jsonStr, contains('clear_transients'));
      expect(jsonStr, contains('WooCommerce transients'));
    });

    test('copyWith properly overrides and preserves fields', () {
      final original = GetSystemStatusToolsModel.fromJson(sampleJson);
      final updated = original.copyWith(
        name: 'Custom Transients',
        action: 'Purge Now',
      );

      expect(updated.id, original.id);
      expect(updated.name, 'Custom Transients');
      expect(updated.action, 'Purge Now');
      expect(updated.description, original.description);
    });

    test('handles missing or empty fields safely', () {
      final emptyModel = GetSystemStatusToolsModel.fromJson({});

      expect(emptyModel.id, isNull);
      expect(emptyModel.name, isNull);
      expect(emptyModel.action, isNull);
      expect(emptyModel.description, isNull);
      expect(emptyModel.links, isNull);
      expect(emptyModel.displayName, 'System Tool');
      expect(emptyModel.displayAction, 'Run Tool');
      expect(emptyModel.displayDescription, 'No description provided.');
      expect(emptyModel.hasAction, false);
      expect(emptyModel.firstHref, '');
      expect(emptyModel.isEmbeddable, false);
    });
  });
}
