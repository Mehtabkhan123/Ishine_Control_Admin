import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/payment_gateways/data/services/payment_gateways_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late PaymentGatewaysService service;

  final sampleGatewaysJson = [
    {
      'id': 'bacs',
      'title': 'Direct Bank Transfer',
      'description': 'BACS payment description',
      'order': 1,
      'enabled': true,
      'method_title': 'Direct bank transfer',
      'settings': {
        'title': {
          'id': 'title',
          'label': 'Title',
          'value': 'Direct Bank Transfer',
        }
      },
    },
    {
      'id': 'cod',
      'title': 'Cash on Delivery',
      'description': 'Pay with cash upon delivery',
      'order': 2,
      'enabled': false,
      'method_title': 'Cash on delivery',
      'needs_setup': true,
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
    service = PaymentGatewaysService(dio: mockDio);
  });

  group('PaymentGatewaysService', () {
    test('fetchPaymentGateways successfully parses gateways list', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            data: sampleGatewaysJson,
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));

      final result = await service.fetchPaymentGateways();

      expect(result.length, 2);
      expect(result[0].id, 'bacs');
      expect(result[0].title, 'Direct Bank Transfer');
      expect(result[0].enabled, true);
      expect(result[1].id, 'cod');
      expect(result[1].enabled, false);
      expect(result[1].needsSetup, true);

      verify(() => mockDio.get(
            any(that: contains('/wp-json/wc/v3/payment_gateways')),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('fetchPaymentGateways throws WooCommerceException on HTTP error status',
        () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            data: {'message': 'Unauthorized access'},
            statusCode: 401,
            requestOptions: RequestOptions(path: ''),
          ));

      expect(
        () => service.fetchPaymentGateways(),
        throwsA(isA<WooCommerceException>().having(
          (e) => e.statusCode,
          'statusCode',
          401,
        )),
      );
    });

    test('fetchPaymentGateway fetches single gateway by ID', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            data: sampleGatewaysJson[0],
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));

      final gateway = await service.fetchPaymentGateway('bacs');

      expect(gateway.id, 'bacs');
      expect(gateway.title, 'Direct Bank Transfer');
      expect(gateway.enabled, true);
    });

    test('updatePaymentGateway sends PUT request and parses updated model', () async {
      when(() => mockDio.put(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            data: {
              'id': 'bacs',
              'title': 'Updated BACS Title',
              'description': 'Updated Description',
              'order': 3,
              'enabled': false,
              'settings': {
                'title': {
                  'id': 'title',
                  'value': 'Updated BACS Title',
                }
              }
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));

      final updated = await service.updatePaymentGateway(
        id: 'bacs',
        data: {
          'title': 'Updated BACS Title',
          'enabled': false,
        },
      );

      expect(updated.id, 'bacs');
      expect(updated.title, 'Updated BACS Title');
      expect(updated.enabled, false);
      expect(updated.order, 3);
    });

    test('updatePaymentGateway throws WooCommerceException on 400 error', () async {
      when(() => mockDio.put(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            data: {'message': 'Invalid parameter(s): enabled', 'code': 'rest_invalid_param'},
            statusCode: 400,
            requestOptions: RequestOptions(path: ''),
          ));

      expect(
        () => service.updatePaymentGateway(
          id: 'bacs',
          data: {'enabled': 'invalid_boolean'},
        ),
        throwsA(isA<WooCommerceException>().having(
          (e) => e.statusCode,
          'statusCode',
          400,
        )),
      );
    });
  });
}
