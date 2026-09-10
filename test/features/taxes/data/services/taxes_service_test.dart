import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/taxes/data/models/post_tax_rates_model.dart';
import 'package:ishine_admin_app/features/taxes/data/services/taxes_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late TaxesService service;

  final sampleTaxesJson = [
    {
      'id': 1,
      'country': 'US',
      'state': 'AL',
      'rate': '4.0000',
      'name': 'State Tax',
      'priority': 1,
      'compound': false,
      'shipping': true,
      'order': 0,
      'class': 'standard',
    },
    {
      'id': 2,
      'country': 'GB',
      'state': '',
      'rate': '20.0000',
      'name': 'VAT',
      'priority': 1,
      'compound': false,
      'shipping': true,
      'order': 1,
      'class': 'standard',
    },
  ];

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    dotenv.testLoad(mergeWith: {
      'WOOCOMMERCE_BASE_URL': 'https://example.com',
      'WOOCOMMERCE_CONSUMER_KEY': 'ck_test_12345',
      'WOOCOMMERCE_CONSUMER_SECRET': 'cs_test_67890',
    });
  });

  setUp(() {
    mockDio = MockDio();
    service = TaxesService(dio: mockDio);
  });

  group('TaxesService', () {
    test('fetchTaxRates successfully parses tax rates and pagination headers',
        () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            data: sampleTaxesJson,
            statusCode: 200,
            headers: Headers.fromMap({
              'x-wp-total': ['2'],
              'x-wp-totalpages': ['1'],
            }),
            requestOptions: RequestOptions(path: ''),
          ));

      final response = await service.fetchTaxRates(page: 1, perPage: 50);

      expect(response.taxRates.length, 2);
      expect(response.totalTaxRates, 2);
      expect(response.totalPages, 1);
      expect(response.taxRates[0].id, 1);
      expect(response.taxRates[0].rate, '4.0000');
      expect(response.taxRates[0].country, 'US');
      expect(response.taxRates[1].id, 2);
      expect(response.taxRates[1].rate, '20.0000');
      expect(response.taxRates[1].name, 'VAT');
    });

    test('fetchTaxRates throws WooCommerceException on HTTP error status',
        () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            data: {'message': 'Invalid API parameters.'},
            statusCode: 400,
            requestOptions: RequestOptions(path: ''),
          ));

      expect(
        () => service.fetchTaxRates(),
        throwsA(isA<WooCommerceException>().having(
          (e) => e.statusCode,
          'statusCode',
          400,
        )),
      );
    });

    test('fetchTaxRate fetches single tax rate by ID', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            data: sampleTaxesJson[0],
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));

      final taxRate = await service.fetchTaxRate(1);

      expect(taxRate.id, 1);
      expect(taxRate.name, 'State Tax');
      expect(taxRate.rate, '4.0000');
    });

    test('createTaxRate posts payload and parses 201 Created response', () async {
      final inputRate = PostTaxRatesModel(
        name: 'New Test Rate',
        rate: '12.5000',
        country: 'US',
        state: 'FL',
        taxClass: 'standard',
      );

      final returnedJson = {
        'id': 99,
        'country': 'US',
        'state': 'FL',
        'rate': '12.5000',
        'name': 'New Test Rate',
        'class': 'standard',
        'priority': 1,
        'compound': false,
        'shipping': true,
        'order': 0,
      };

      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            data: returnedJson,
            statusCode: 201,
            requestOptions: RequestOptions(path: ''),
          ));

      final result = await service.createTaxRate(inputRate);

      expect(result.id, 99);
      expect(result.name, 'New Test Rate');
      expect(result.rate, '12.5000');
      expect(result.taxClass, 'standard');

      verify(() => mockDio.post(
            any(that: contains('/wp-json/wc/v3/taxes')),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('createTaxRate throws WooCommerceException on 400 response', () async {
      final inputRate = PostTaxRatesModel(
        name: 'Bad Rate',
        rate: 'invalid',
      );

      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            data: {
              'code': 'woocommerce_rest_invalid_tax_rate',
              'message': 'Rate must be numeric.',
            },
            statusCode: 400,
            requestOptions: RequestOptions(path: ''),
          ));

      expect(
        () => service.createTaxRate(inputRate),
        throwsA(isA<WooCommerceException>().having(
          (e) => e.message,
          'message',
          'Rate must be numeric.',
        )),
      );
    });
  });
}
