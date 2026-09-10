import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/shipping/data/services/shipping_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ShippingService service;

  final sampleZonesJson = [
    {
      'id': 1,
      'name': 'Domestic (US)',
      'order': 0,
      '_links': {
        'self': [
          {'href': 'https://example.com/wp-json/wc/v3/shipping/zones/1'}
        ]
      }
    },
    {
      'id': 2,
      'name': 'Europe & UK',
      'order': 1,
      '_links': {
        'self': [
          {'href': 'https://example.com/wp-json/wc/v3/shipping/zones/2'}
        ]
      }
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
    service = ShippingService(dio: mockDio);
  });

  group('ShippingService', () {
    test('fetchShippingZones successfully parses zones and headers', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            data: sampleZonesJson,
            statusCode: 200,
            headers: Headers.fromMap({
              'x-wp-total': ['2'],
              'x-wp-totalpages': ['1'],
            }),
            requestOptions: RequestOptions(path: ''),
          ));

      final response = await service.fetchShippingZones(page: 1, perPage: 50);

      expect(response.zones.length, 2);
      expect(response.totalZones, 2);
      expect(response.totalPages, 1);
      expect(response.zones[0].id, 1);
      expect(response.zones[0].name, 'Domestic (US)');
      expect(response.zones[0].order, 0);
      expect(response.zones[1].id, 2);
      expect(response.zones[1].name, 'Europe & UK');
      expect(response.zones[1].order, 1);
    });

    test('fetchShippingZones throws WooCommerceException on HTTP error status',
        () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            data: {'message': 'The API route was not found.'},
            statusCode: 404,
            requestOptions: RequestOptions(path: ''),
          ));

      expect(
        () => service.fetchShippingZones(),
        throwsA(isA<WooCommerceException>().having(
          (e) => e.statusCode,
          'statusCode',
          404,
        )),
      );
    });

    test('fetchShippingZone fetches single zone by ID', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            data: sampleZonesJson[0],
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));

      final zone = await service.fetchShippingZone(1);

      expect(zone.id, 1);
      expect(zone.name, 'Domestic (US)');
      expect(zone.order, 0);
    });
  });
}
