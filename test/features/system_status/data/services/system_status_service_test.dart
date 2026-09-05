import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/system_status/data/services/system_status_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late SystemStatusService service;

  final sampleSystemStatusJson = {
    'environment': {
      'home_url': 'https://example.com',
      'site_url': 'https://example.com',
      'store_id': 'store_123',
      'version': '9.4.0',
      'log_directory': '/var/log/wc',
      'log_directory_writable': true,
      'wp_version': '6.7.1',
      'wp_multisite': false,
      'wp_memory_limit': 268435456,
      'wp_debug_mode': false,
      'wp_cron': true,
      'language': 'en_US',
      'server_info': 'LiteSpeed',
      'php_version': '8.2.20',
      'mysql_version_string': '10.11.8-MariaDB',
      'default_timezone': 'UTC',
      'remote_get_successful': true,
      'remote_get_response': 200,
    },
    'database': {
      'wc_database_version': '9.4.0',
      'database_prefix': 'wp_',
      'database_size': {'data': 12.5, 'index': 4.2},
    },
    'active_plugins': [
      {
        'plugin': 'woocommerce/woocommerce.php',
        'name': 'WooCommerce',
        'version': '9.4.0',
        'version_latest': '9.4.0',
        'url': 'https://woocommerce.com',
        'network_activated': false,
      },
    ],
    'inactive_plugins': [
      {
        'plugin': 'hello-dolly/hello.php',
        'name': 'Hello Dolly',
        'version': '1.7.2',
        'network_activated': false,
      },
    ],
    'dropins_mu_plugins': {
      'dropins': [
        {'plugin': 'advanced-cache.php', 'name': 'advanced-cache.php'}
      ],
      'mu_plugins': ['custom-loader.php'],
    },
    'theme': {
      'name': 'Astra',
      'version': '4.8.0',
      'is_child_theme': false,
      'has_woocommerce_support': true,
    },
    'settings': {
      'api_enabled': true,
      'force_ssl': true,
      'currency': 'USD',
      'currency_symbol': '\$',
      'currency_position': 'left',
      'thousand_separator': ',',
      'decimal_separator': '.',
      'number_of_decimals': 2,
      'HPOS_enabled': true,
      'enabled_features': ['hpos', 'analytics'],
    },
    'security': {
      'secure_connection': true,
      'hide_errors': true,
    },
    'pages': [
      {
        'page_name': 'Shop',
        'page_id': '10',
        'page_set': true,
        'page_exists': true,
        'page_visible': true,
      }
    ],
    'post_type_counts': [
      {'type': 'product', 'count': '42'}
    ],
    'logging': {
      'logging_enabled': true,
      'retention_period_days': 30,
      'level_threshold': 'warning',
    }
  };

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    dotenv.testLoad(mergeWith: {
      'WOOCOMMERCE_BASE_URL': 'https://example.com',
      'WOOCOMMERCE_CONSUMER_KEY': 'ck_test_key',
      'WOOCOMMERCE_CONSUMER_SECRET': 'cs_test_secret',
    });
  });

  setUp(() {
    mockDio = MockDio();
    service = SystemStatusService(dio: mockDio);
  });

  group('SystemStatusService - fetchSystemStatus()', () {
    test('successfully fetches and parses GETSystemStatusModel with 200 OK', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            data: sampleSystemStatusJson,
            statusCode: 200,
            requestOptions: RequestOptions(path: 'https://example.com/wp-json/wc/v3/system_status'),
          ));

      final model = await service.fetchSystemStatus();

      expect(model.environment?.homeUrl, 'https://example.com');
      expect(model.environment?.version, '9.4.0');
      expect(model.database?.wcDatabaseVersion, '9.4.0');
      expect(model.activePlugins?.length, 1);
      expect(model.activePlugins?.first.name, 'WooCommerce');
      expect(model.inactivePlugins?.length, 1);
      expect(model.inactivePlugins?.first.name, 'Hello Dolly');
      expect(model.dropinsMuPlugins?.dropins?.first.name, 'advanced-cache.php');
      expect(model.theme?.name, 'Astra');
      expect(model.settings?.currency, 'USD');
      expect(model.settings?.enabledFeatures, contains('hpos'));
      expect(model.security?.secureConnection, true);
      expect(model.pages?.first.pageName, 'Shop');
      expect(model.postTypeCounts?.first.type, 'product');
      expect(model.postTypeCounts?.first.count, '42');
      expect(model.logging?.loggingEnabled, true);

      // Verify domain mapping works as expected
      final domain = model.toDomain(responseTimeMs: 95);
      expect(domain.siteUrl, 'https://example.com');
      expect(domain.wcVersion, '9.4.0');
      expect(domain.isSecure, true);
      expect(domain.responseTimeMs, 95);
    });

    test('supports Header Auth mode with Authorization Basic header', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((invocation) async {
        final options = invocation.namedArguments[#options] as Options;
        final headers = options.headers;

        // Verify Basic Auth header was generated from ck_test_key:cs_test_secret
        final expectedAuth = base64Encode(utf8.encode('ck_test_key:cs_test_secret'));
        expect(headers?['Authorization'], 'Basic $expectedAuth');

        return Response(
          data: sampleSystemStatusJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );
      });

      final model = await service.fetchSystemStatus(
        authMode: WooCommerceAuthMode.header,
      );
      expect(model.environment?.version, '9.4.0');
    });

    test('supports Query Parameter Auth mode with consumer_key & consumer_secret params', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((invocation) async {
        final queryParams = invocation.namedArguments[#queryParameters] as Map<String, dynamic>?;
        final options = invocation.namedArguments[#options] as Options;

        expect(queryParams?['consumer_key'], 'ck_test_key');
        expect(queryParams?['consumer_secret'], 'cs_test_secret');
        expect(options.headers?['Authorization'], isNull);

        return Response(
          data: sampleSystemStatusJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );
      });

      final model = await service.fetchSystemStatus(
        authMode: WooCommerceAuthMode.queryParameters,
      );
      expect(model.environment?.version, '9.4.0');
    });

    test('supports dynamic base URL and credential overrides', () async {
      when(() => mockDio.get(
            'https://custom-store.com/wp-json/wc/v3/system_status',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((invocation) async {
        final options = invocation.namedArguments[#options] as Options;
        final expectedAuth = base64Encode(utf8.encode('custom_key:custom_secret'));
        expect(options.headers?['Authorization'], 'Basic $expectedAuth');

        return Response(
          data: sampleSystemStatusJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );
      });

      final model = await service.fetchSystemStatus(
        baseUrl: 'https://custom-store.com/', // Trailing slash should be sanitized
        consumerKey: 'custom_key',
        consumerSecret: 'custom_secret',
        authMode: WooCommerceAuthMode.header,
      );
      expect(model.environment?.version, '9.4.0');
    });

    test('throws WooCommerceException on HTTP 401 Unauthorized', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            data: {'code': 'woocommerce_rest_cannot_view', 'message': 'Sorry, you cannot list resources.'},
            statusCode: 401,
            requestOptions: RequestOptions(path: ''),
          ));

      expect(
        () => service.fetchSystemStatus(),
        throwsA(
          isA<WooCommerceException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', contains('401')),
        ),
      );
    });

    test('throws WooCommerceException on HTTP 404 Not Found', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            data: {'code': 'rest_no_route', 'message': 'No route was found matching the URL and request method.'},
            statusCode: 404,
            requestOptions: RequestOptions(path: ''),
          ));

      expect(
        () => service.fetchSystemStatus(),
        throwsA(
          isA<WooCommerceException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.message, 'message', contains('404')),
        ),
      );
    });

    test('throws WooCommerceParseException on corrupted or invalid JSON response', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            data: ['not', 'a', 'valid', 'map'],
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));

      expect(
        () => service.fetchSystemStatus(),
        throwsA(isA<WooCommerceParseException>()),
      );
    });

    test('throws WooCommerceException when network timeout occurs', () async {
      when(() => mockDio.get(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(
        () => service.fetchSystemStatus(),
        throwsA(
          isA<WooCommerceException>()
              .having((e) => e.statusCode, 'statusCode', 408)
              .having((e) => e.message, 'message', contains('timed out')),
        ),
      );
    });
  });
}
