import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/products/data/services/media_upload_service.dart';
import 'package:ishine_admin_app/features/system_status/data/services/system_status_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late MediaUploadService service;

  setUpAll(() {
    dotenv.testLoad(mergeWith: {
      'WOOCOMMERCE_BASE_URL': 'https://example.com',
      'WOOCOMMERCE_CONSUMER_KEY': 'ck_test123',
      'WOOCOMMERCE_CONSUMER_SECRET': 'cs_test456',
    });
  });

  setUp(() {
    mockDio = MockDio();
    service = MediaUploadService(dio: mockDio);
  });

  group('MediaUploadService', () {
    test('throws WooCommerceException when image bytes are empty', () async {
      expect(
        () => service.uploadMedia(bytes: Uint8List(0), filename: 'empty.jpg'),
        throwsA(isA<WooCommerceException>()),
      );
    });

    test('throws WooCommerceException when consumer credentials are missing', () async {
      expect(
        () => service.uploadMedia(
          bytes: Uint8List.fromList([1, 2, 3]),
          filename: 'test.jpg',
          consumerKey: '',
          consumerSecret: '',
        ),
        throwsA(isA<WooCommerceException>()),
      );
    });

    test('throws WooCommerceException when base URL is empty', () async {
      expect(
        () => service.uploadMedia(
          bytes: Uint8List.fromList([1, 2, 3]),
          filename: 'test.jpg',
          baseUrl: '',
        ),
        throwsA(isA<WooCommerceException>()),
      );
    });

    test('throws WooCommerceException explaining direct upload is not supported by REST keys', () async {
      final sampleBytes = Uint8List.fromList([1, 2, 3, 4]);

      expect(
        () => service.uploadMedia(
          bytes: sampleBytes,
          filename: 'sample.jpg',
        ),
        throwsA(
          predicate<WooCommerceException>((e) =>
              e.statusCode == 405 &&
              e.message.contains('Direct media file upload is not supported')),
        ),
      );
    });
  });
}
