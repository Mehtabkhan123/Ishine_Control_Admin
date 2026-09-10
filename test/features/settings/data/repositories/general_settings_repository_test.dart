import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/settings/data/models/get_general_settings_model.dart';
import 'package:ishine_admin_app/features/settings/data/repositories/general_settings_repository.dart';
import 'package:ishine_admin_app/features/settings/data/services/general_settings_service.dart';
import 'package:ishine_admin_app/features/system_status/data/services/system_status_service.dart';
import 'package:mocktail/mocktail.dart';

class MockGeneralSettingsService extends Mock implements GeneralSettingsService {}

void main() {
  late MockGeneralSettingsService mockService;
  late GeneralSettingsRepository repository;

  setUpAll(() {
    registerFallbackValue(WooCommerceAuthMode.auto);
  });

  final sampleSettings = [
    GetGeneralSettingsModel(
      id: 'woocommerce_store_address',
      label: 'Address line 1',
      value: '123 Main St',
    ),
    GetGeneralSettingsModel(
      id: 'woocommerce_currency',
      label: 'Currency',
      value: 'USD',
    ),
  ];

  setUp(() {
    mockService = MockGeneralSettingsService();
    repository = GeneralSettingsRepository(service: mockService);
  });

  group('GeneralSettingsRepository', () {
    test('getGeneralSettings caches response and does not invoke service twice', () async {
      when(() => mockService.fetchGeneralSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => sampleSettings);

      final result1 = await repository.getGeneralSettings();
      final result2 = await repository.getGeneralSettings();

      expect(result1.length, 2);
      expect(result2.length, 2);
      verify(() => mockService.fetchGeneralSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('getGeneralSettings with forceRefresh queries service again', () async {
      when(() => mockService.fetchGeneralSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => sampleSettings);

      await repository.getGeneralSettings();
      await repository.getGeneralSettings(forceRefresh: true);

      verify(() => mockService.fetchGeneralSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).called(2);
    });

    test('deduplicates concurrent in-flight requests', () async {
      when(() => mockService.fetchGeneralSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 30));
        return sampleSettings;
      });

      final results = await Future.wait([
        repository.getGeneralSettings(),
        repository.getGeneralSettings(),
        repository.getGeneralSettings(),
      ]);

      expect(results[0].length, 2);
      expect(results[1].length, 2);
      expect(results[2].length, 2);
      verify(() => mockService.fetchGeneralSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('getGeneralSetting retrieves single setting and caches it', () async {
      final currencySetting = GetGeneralSettingsModel(
        id: 'woocommerce_currency',
        label: 'Currency',
        value: 'USD',
      );

      when(() => mockService.fetchGeneralSetting(
            id: 'woocommerce_currency',
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => currencySetting);

      final result1 = await repository.getGeneralSetting('woocommerce_currency');
      final result2 = await repository.getGeneralSetting('woocommerce_currency');

      expect(result1.id, 'woocommerce_currency');
      expect(result2.id, 'woocommerce_currency');
      verify(() => mockService.fetchGeneralSetting(
            id: 'woocommerce_currency',
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('clearCache invalidates cached settings', () async {
      when(() => mockService.fetchGeneralSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => sampleSettings);

      await repository.getGeneralSettings();
      repository.clearCache();
      await repository.getGeneralSettings();

      verify(() => mockService.fetchGeneralSettings(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).called(2);
    });
  });
}
