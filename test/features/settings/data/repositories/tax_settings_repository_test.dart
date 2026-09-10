import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/settings/data/models/get_tax_settings_model.dart';
import 'package:ishine_admin_app/features/settings/data/repositories/tax_settings_repository.dart';
import 'package:ishine_admin_app/features/settings/data/services/tax_settings_service.dart';
import 'package:ishine_admin_app/features/system_status/data/services/system_status_service.dart';
import 'package:mocktail/mocktail.dart';

class MockTaxSettingsService extends Mock implements TaxSettingsService {}

void main() {
  late MockTaxSettingsService mockService;
  late TaxSettingsRepository repository;

  setUpAll(() {
    registerFallbackValue(WooCommerceAuthMode.auto);
  });

  final sampleTaxSettings = [
    GetTextSettingsModel(
      id: 'woocommerce_calc_taxes',
      label: 'Enable taxes',
      value: 'yes',
    ),
    GetTextSettingsModel(
      id: 'woocommerce_prices_include_tax',
      label: 'Prices entered with tax',
      value: 'no',
    ),
  ];

  setUp(() {
    mockService = MockTaxSettingsService();
    repository = TaxSettingsRepository(service: mockService);
  });

  group('TaxSettingsRepository', () {
    test('getTaxSettings caches response and does not invoke service twice',
        () async {
      when(() => mockService.fetchTaxSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => sampleTaxSettings);

      final result1 = await repository.getTaxSettings();
      final result2 = await repository.getTaxSettings();

      expect(result1.length, 2);
      expect(result2.length, 2);
      verify(() => mockService.fetchTaxSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('getTaxSettings with forceRefresh queries service again', () async {
      when(() => mockService.fetchTaxSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => sampleTaxSettings);

      await repository.getTaxSettings();
      await repository.getTaxSettings(forceRefresh: true);

      verify(() => mockService.fetchTaxSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).called(2);
    });

    test('deduplicates concurrent in-flight requests', () async {
      when(() => mockService.fetchTaxSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 30));
        return sampleTaxSettings;
      });

      final results = await Future.wait([
        repository.getTaxSettings(),
        repository.getTaxSettings(),
        repository.getTaxSettings(),
      ]);

      expect(results[0].length, 2);
      expect(results[1].length, 2);
      expect(results[2].length, 2);
      verify(() => mockService.fetchTaxSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('getTaxSetting retrieves single setting and caches it', () async {
      final singleSetting = GetTextSettingsModel(
        id: 'woocommerce_calc_taxes',
        label: 'Enable taxes',
        value: 'yes',
      );

      when(() => mockService.fetchTaxSetting(
            id: 'woocommerce_calc_taxes',
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => singleSetting);

      final r1 = await repository.getTaxSetting('woocommerce_calc_taxes');
      final r2 = await repository.getTaxSetting('woocommerce_calc_taxes');

      expect(r1.id, 'woocommerce_calc_taxes');
      expect(r2.id, 'woocommerce_calc_taxes');
      verify(() => mockService.fetchTaxSetting(
            id: 'woocommerce_calc_taxes',
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('clearCache invalidates cached settings', () async {
      when(() => mockService.fetchTaxSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => sampleTaxSettings);

      await repository.getTaxSettings();
      repository.clearCache();
      await repository.getTaxSettings();

      verify(() => mockService.fetchTaxSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).called(2);
    });
  });
}
