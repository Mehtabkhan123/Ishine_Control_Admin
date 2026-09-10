import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/settings/data/services/tax_settings_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late TaxSettingsService service;

  final sampleTaxSettingsJson = [
    {
      'id': 'woocommerce_calc_taxes',
      'label': 'Enable taxes',
      'description': 'Enable tax calculations and its display.',
      'type': 'checkbox',
      'default': 'no',
      'value': 'yes',
    },
    {
      'id': 'woocommerce_prices_include_tax',
      'label': 'Prices entered with tax',
      'description': 'This option indicates whether prices include tax.',
      'type': 'checkbox',
      'default': 'no',
      'value': 'no',
    },
    {
      'id': 'woocommerce_tax_based_on',
      'label': 'Calculate tax based on',
      'description':
          'This option determines which address is used to calculate tax.',
      'type': 'select',
      'options': {
        'shipping': 'Customer shipping address',
        'billing': 'Customer billing address',
        'base': 'Shop base address',
      },
      'default': 'shipping',
      'value': 'shipping',
    }
  ];

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    dotenv.testLoad(mergeWith: {
      'WOOCOMMERCE_BASE_URL': 'https://example.com',
      'WOOCOMMERCE_CONSUMER_KEY': 'ck_test_tax_123',
      'WOOCOMMERCE_CONSUMER_SECRET': 'cs_test_tax_456',
    });
  });

  setUp(() {
    mockDio = MockDio();
    service = TaxSettingsService(dio: mockDio);
  });

  group('TaxSettingsService', () {
    test('fetchTaxSettings successfully parses tax settings list', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/wp-json/wc/v3/settings/tax'),
          statusCode: 200,
          data: sampleTaxSettingsJson,
        ),
      );

      final result = await service.fetchTaxSettings();

      expect(result.length, 3);
      expect(result[0].id, 'woocommerce_calc_taxes');
      expect(result[0].isCheckbox, isTrue);
      expect(result[0].value, 'yes');
      expect(result[1].id, 'woocommerce_prices_include_tax');
      expect(result[1].isCheckbox, isTrue);
      expect(result[2].id, 'woocommerce_tax_based_on');
      expect(result[2].isSelect, isTrue);
    });

    test('fetchTaxSettings throws WooCommerceException on HTTP error status',
        () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/wp-json/wc/v3/settings/tax'),
          statusCode: 401,
          data: {
            'code': 'woocommerce_rest_cannot_view',
            'message': 'Sorry, you cannot list resources.',
          },
        ),
      );

      expect(
        () => service.fetchTaxSettings(),
        throwsA(isA<WooCommerceException>().having(
          (e) => e.statusCode,
          'statusCode',
          401,
        )),
      );
    });

    test('fetchTaxSetting fetches single setting by ID', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
              path: '/wp-json/wc/v3/settings/tax/woocommerce_calc_taxes'),
          statusCode: 200,
          data: sampleTaxSettingsJson[0],
        ),
      );

      final result =
          await service.fetchTaxSetting(id: 'woocommerce_calc_taxes');

      expect(result.id, 'woocommerce_calc_taxes');
      expect(result.boolValue, isTrue);
    });

    test(
        'throws WooCommerceException if credentials or base URL are missing',
        () async {
      expect(
        () => service.fetchTaxSettings(baseUrl: ''),
        throwsA(isA<WooCommerceException>()),
      );

      expect(
        () => service.fetchTaxSettings(consumerKey: ''),
        throwsA(isA<WooCommerceException>()),
      );
    });
  });
}
