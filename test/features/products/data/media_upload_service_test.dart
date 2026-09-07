import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/config/env_config.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/products/data/services/media_upload_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late MediaUploadService service;

  setUpAll(() {
    dotenv.testLoad(mergeWith: {
      'WOOCOMMERCE_BASE_URL': 'https://example.com',
      'WOOCOMMERCE_CONSUMER_KEY': 'ck_test',
      'WOOCOMMERCE_CONSUMER_SECRET': 'cs_test',
    });
  });

  setUp(() {
    mockDio = MockDio();
    service = MediaUploadService(dio: mockDio);
    EnvConfig.setWordpressCredentials(username: null, appPassword: null);
  });

  group('MediaUploadService', () {
    test('throws WooCommerceException when image bytes are empty', () async {
      expect(
        () => service.uploadMedia(bytes: Uint8List(0), filename: 'empty.jpg'),
        throwsA(isA<WooCommerceException>()),
      );
    });

    test('uploads via staging gateway when no WordPress app password is configured', () async {
      final sampleBytes = Uint8List.fromList([10, 20, 30, 40]);

      when(() => mockDio.post(
            'https://freeimage.host/api/1/upload',
            data: any(named: 'data'),
            options: any(named: 'options'),
            onSendProgress: any(named: 'onSendProgress'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: 'https://freeimage.host/api/1/upload'),
            statusCode: 200,
            data: {
              'status_code': 200,
              'image': {
                'name': 'product_image.jpg',
                'url': 'https://iili.io/sample123.jpg',
              },
            },
          ));

      final result = await service.uploadMedia(
        bytes: sampleBytes,
        filename: 'product_image.jpg',
      );

      expect(result.src, 'https://iili.io/sample123.jpg');
      expect(result.name, 'product_image.jpg');
    });

    test('uploads directly to WordPress when WordPress app password is configured', () async {
      EnvConfig.setWordpressCredentials(username: 'admin', appPassword: 'app_pass_123');
      final sampleBytes = Uint8List.fromList([1, 2, 3, 4]);

      when(() => mockDio.post(
            'https://example.com/wp-json/wp/v2/media',
            data: any(named: 'data'),
            options: any(named: 'options'),
            onSendProgress: any(named: 'onSendProgress'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: 'https://example.com/wp-json/wp/v2/media'),
            statusCode: 201,
            data: {
              'id': 789,
              'source_url': 'https://example.com/wp-content/uploads/sample.jpg',
            },
          ));

      final result = await service.uploadMedia(
        bytes: sampleBytes,
        filename: 'sample.jpg',
      );

      expect(result.id, 789);
      expect(result.src, 'https://example.com/wp-content/uploads/sample.jpg');
    });

    test('falls back to staging gateway if direct WordPress upload fails with 401', () async {
      EnvConfig.setWordpressCredentials(username: 'admin', appPassword: 'bad_password');
      final sampleBytes = Uint8List.fromList([5, 6, 7, 8]);

      // Direct WP fails with 401
      when(() => mockDio.post(
            'https://example.com/wp-json/wp/v2/media',
            data: any(named: 'data'),
            options: any(named: 'options'),
            onSendProgress: any(named: 'onSendProgress'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: 'https://example.com/wp-json/wp/v2/media'),
            statusCode: 401,
            data: {
              'code': 'rest_cannot_create',
              'message': 'Sorry, you are not allowed to create posts as this user.',
            },
          ));

      // Fallback staging succeeds
      when(() => mockDio.post(
            'https://freeimage.host/api/1/upload',
            data: any(named: 'data'),
            options: any(named: 'options'),
            onSendProgress: any(named: 'onSendProgress'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: 'https://freeimage.host/api/1/upload'),
            statusCode: 200,
            data: {
              'image': {
                'url': 'https://iili.io/fallback.jpg',
              },
            },
          ));

      final result = await service.uploadMedia(
        bytes: sampleBytes,
        filename: 'fallback.jpg',
      );

      expect(result.src, 'https://iili.io/fallback.jpg');
    });
  });
}
