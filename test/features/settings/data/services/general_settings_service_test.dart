import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/settings/data/services/general_settings_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late GeneralSettingsService service;

  final sampleSettingsJson = [
    {
      'id': 'woocommerce_store_address',
      'label': 'Address line 1',
      'description': 'The street address for your business location.',
      'type': 'text',
      'default': '',
      'tip': 'The street address for your business location.',
      'value': '123 Market St',
    },
    {
      'id': 'woocommerce_calc_taxes',
      'label': 'Enable taxes',
      'description': 'Enable tax rates and calculations',
      'type': 'checkbox',
      'default': 'no',
      'tip': '',
      'value': 'yes',
    },
    {
      'id': 'woocommerce_currency',
      'label': 'Currency',
      'description': 'This controls what currency prices are listed at.',
      'type': 'select',
      'options': {
        'USD': 'United States dollar (\$)',
        'EUR': 'Euro (€)',
      },
      'default': 'USD',
      'value': 'USD',
    }
  ];

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    dotenv.testLoad(mergeWith: {
      'WOOCOMMERCE_BASE_URL': 'https://example.com',
      'WOOCOMMERCE_CONSUMER_KEY': 'ck_test_key_123',
      'WOOCOMMERCE_CONSUMER_SECRET': 'cs_test_secret_456',
    });
  });

  setUp(() {
    mockDio = MockDio();
    service = GeneralSettingsService(dio: mockDio);
  });

  group('GeneralSettingsService', () {
    test('fetchGeneralSettings successfully parses general settings list', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/wp-json/wc/v3/settings/general'),
          statusCode: 200,
          data: sampleSettingsJson,
        ),
      );

      final result = await service.fetchGeneralSettings();

      expect(result.length, 3);
      expect(result[0].id, 'woocommerce_store_address');
      expect(result[0].value, '123 Market St');
      expect(result[1].id, 'woocommerce_calc_taxes');
      expect(result[1].isCheckbox, isTrue);
      expect(result[2].id, 'woocommerce_currency');
      expect(result[2].isSelect, isTrue);
    });

    test('fetchGeneralSettings throws WooCommerceException on HTTP error status', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/wp-json/wc/v3/settings/general'),
          statusCode: 401,
          data: {
            'code': 'woocommerce_rest_cannot_view',
            'message': 'Sorry, you cannot list resources.',
          },
        ),
      );

      expect(
        () => service.fetchGeneralSettings(),
        throwsA(isA<WooCommerceException>().having(
          (e) => e.statusCode,
          'statusCode',
          401,
        )),
      );
    });

    test('fetchGeneralSetting fetches single setting by ID', () async {
      final singleJson = {
        'id': 'woocommerce_currency',
        'label': 'Currency',
        'type': 'select',
        'value': 'USD',
      };

      when(() => mockDio.get(
            any(that: contains('/settings/general/woocommerce_currency')),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/wp-json/wc/v3/settings/general/woocommerce_currency',
          ),
          statusCode: 200,
          data: singleJson,
        ),
      );

      final result = await service.fetchGeneralSetting(id: 'woocommerce_currency');

      expect(result.id, 'woocommerce_currency');
      expect(result.value, 'USD');
    });

    test('throws WooCommerceException if credentials or base URL are missing', () async {
      expect(
        () => service.fetchGeneralSettings(baseUrl: ''),
        throwsA(isA<WooCommerceException>()),
      );
      expect(
        () => service.fetchGeneralSettings(consumerKey: ''),
        throwsA(isA<WooCommerceException>()),
      );
    });
  });
}
