import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/settings/data/models/get_product_settings_model.dart';
import 'package:ishine_admin_app/features/settings/data/repositories/product_settings_repository.dart';
import 'package:ishine_admin_app/features/settings/data/services/product_settings_service.dart';
import 'package:ishine_admin_app/features/system_status/data/services/system_status_service.dart';
import 'package:mocktail/mocktail.dart';

class MockProductSettingsService extends Mock implements ProductSettingsService {}

void main() {
  late MockProductSettingsService mockService;
  late ProductSettingsRepository repository;

  setUpAll(() {
    registerFallbackValue(WooCommerceAuthMode.auto);
  });

  final sampleProductSettings = [
    GetProductSettingsModel(
      id: 'woocommerce_weight_unit',
      label: 'Weight unit',
      value: 'kg',
    ),
    GetProductSettingsModel(
      id: 'woocommerce_manage_stock',
      label: 'Manage stock',
      value: 'yes',
    ),
  ];

  setUp(() {
    mockService = MockProductSettingsService();
    repository = ProductSettingsRepository(service: mockService);
  });

  group('ProductSettingsRepository', () {
    test('getProductSettings caches response and does not invoke service twice',
        () async {
      when(() => mockService.fetchProductSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => sampleProductSettings);

      final result1 = await repository.getProductSettings();
      final result2 = await repository.getProductSettings();

      expect(result1.length, 2);
      expect(result2.length, 2);
      verify(() => mockService.fetchProductSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('getProductSettings with forceRefresh queries service again', () async {
      when(() => mockService.fetchProductSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => sampleProductSettings);

      await repository.getProductSettings();
      await repository.getProductSettings(forceRefresh: true);

      verify(() => mockService.fetchProductSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).called(2);
    });

    test('deduplicates concurrent in-flight requests', () async {
      when(() => mockService.fetchProductSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 30));
        return sampleProductSettings;
      });

      final results = await Future.wait([
        repository.getProductSettings(),
        repository.getProductSettings(),
        repository.getProductSettings(),
      ]);

      expect(results[0].length, 2);
      expect(results[1].length, 2);
      expect(results[2].length, 2);
      verify(() => mockService.fetchProductSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('getProductSetting retrieves single setting and caches it', () async {
      final weightSetting = GetProductSettingsModel(
        id: 'woocommerce_weight_unit',
        label: 'Weight unit',
        value: 'kg',
      );

      when(() => mockService.fetchProductSetting(
            id: 'woocommerce_weight_unit',
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => weightSetting);

      final result1 =
          await repository.getProductSetting('woocommerce_weight_unit');
      final result2 =
          await repository.getProductSetting('woocommerce_weight_unit');

      expect(result1.id, 'woocommerce_weight_unit');
      expect(result2.id, 'woocommerce_weight_unit');
      verify(() => mockService.fetchProductSetting(
            id: 'woocommerce_weight_unit',
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('clearCache invalidates cached settings', () async {
      when(() => mockService.fetchProductSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => sampleProductSettings);

      await repository.getProductSettings();
      repository.clearCache();
      await repository.getProductSettings();

      verify(() => mockService.fetchProductSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).called(2);
    });
  });
}
