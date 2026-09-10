import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/settings/data/services/product_settings_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ProductSettingsService service;

  final sampleProductSettingsJson = [
    {
      'id': 'woocommerce_weight_unit',
      'label': 'Weight unit',
      'description': 'This controls what unit you define weights in.',
      'type': 'select',
      'options': {
        'kg': 'kg',
        'g': 'g',
        'lbs': 'lbs',
      },
      'default': 'kg',
      'value': 'kg',
    },
    {
      'id': 'woocommerce_manage_stock',
      'label': 'Manage stock',
      'description': 'Enable stock management',
      'type': 'checkbox',
      'default': 'no',
      'tip': '',
      'value': 'yes',
    },
    {
      'id': 'woocommerce_hold_stock_minutes',
      'label': 'Hold stock (minutes)',
      'description': 'Hold stock for unpaid orders.',
      'type': 'number',
      'default': 60,
      'value': 60,
    }
  ];

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    dotenv.testLoad(mergeWith: {
      'WOOCOMMERCE_BASE_URL': 'https://example.com',
      'WOOCOMMERCE_CONSUMER_KEY': 'ck_test_product_123',
      'WOOCOMMERCE_CONSUMER_SECRET': 'cs_test_product_456',
    });
  });

  setUp(() {
    mockDio = MockDio();
    service = ProductSettingsService(dio: mockDio);
  });

  group('ProductSettingsService', () {
    test('fetchProductSettings successfully parses product settings list', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/wp-json/wc/v3/settings/products'),
          statusCode: 200,
          data: sampleProductSettingsJson,
        ),
      );

      final result = await service.fetchProductSettings();

      expect(result.length, 3);
      expect(result[0].id, 'woocommerce_weight_unit');
      expect(result[0].isSelect, isTrue);
      expect(result[0].value, 'kg');
      expect(result[1].id, 'woocommerce_manage_stock');
      expect(result[1].isCheckbox, isTrue);
      expect(result[2].id, 'woocommerce_hold_stock_minutes');
      expect(result[2].isNumber, isTrue);
    });

    test('fetchProductSettings throws WooCommerceException on HTTP error status', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/wp-json/wc/v3/settings/products'),
          statusCode: 401,
          data: {
            'code': 'woocommerce_rest_cannot_view',
            'message': 'Sorry, you cannot list resources.',
          },
        ),
      );

      expect(
        () => service.fetchProductSettings(),
        throwsA(isA<WooCommerceException>().having(
          (e) => e.statusCode,
          'statusCode',
          401,
        )),
      );
    });

    test('fetchProductSetting fetches single setting by ID', () async {
      final singleJson = {
        'id': 'woocommerce_weight_unit',
        'label': 'Weight unit',
        'type': 'select',
        'value': 'kg',
      };

      when(() => mockDio.get(
            any(that: contains('/settings/products/woocommerce_weight_unit')),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/wp-json/wc/v3/settings/products/woocommerce_weight_unit',
          ),
          statusCode: 200,
          data: singleJson,
        ),
      );

      final result =
          await service.fetchProductSetting(id: 'woocommerce_weight_unit');

      expect(result.id, 'woocommerce_weight_unit');
      expect(result.value, 'kg');
    });

    test('throws WooCommerceException if credentials or base URL are missing', () async {
      expect(
        () => service.fetchProductSettings(baseUrl: ''),
        throwsA(isA<WooCommerceException>()),
      );
      expect(
        () => service.fetchProductSettings(consumerKey: ''),
        throwsA(isA<WooCommerceException>()),
      );
    });
  });
}
