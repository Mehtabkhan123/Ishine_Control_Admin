import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/settings/bloc/tax_settings_bloc.dart';
import 'package:ishine_admin_app/features/settings/bloc/tax_settings_event.dart';
import 'package:ishine_admin_app/features/settings/bloc/tax_settings_state.dart';
import 'package:ishine_admin_app/features/settings/data/models/get_tax_settings_model.dart';
import 'package:ishine_admin_app/features/settings/data/repositories/tax_settings_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockTaxSettingsRepository extends Mock implements TaxSettingsRepository {}

void main() {
  late MockTaxSettingsRepository mockRepository;

  final sampleTaxSettings = [
    GetTextSettingsModel(
      id: 'woocommerce_calc_taxes',
      label: 'Enable taxes',
      description: 'Enable tax calculations and its display.',
      type: 'checkbox',
      value: 'yes',
    ),
    GetTextSettingsModel(
      id: 'woocommerce_prices_include_tax',
      label: 'Prices entered with tax',
      type: 'checkbox',
      value: 'no',
    ),
    GetTextSettingsModel(
      id: 'woocommerce_tax_based_on',
      label: 'Calculate tax based on',
      type: 'select',
      value: 'shipping',
    ),
  ];

  setUp(() {
    mockRepository = MockTaxSettingsRepository();
  });

  group('TaxSettingsBloc', () {
    test('initial state has correct default values', () {
      final bloc = TaxSettingsBloc(repository: mockRepository);
      expect(bloc.state.status, TaxSettingsStatus.initial);
      expect(bloc.state.allSettings, isEmpty);
      expect(bloc.state.filteredSettings, isEmpty);
      expect(bloc.state.searchQuery, '');
      expect(bloc.state.selectedTypeFilter, isNull);
    });

    blocTest<TaxSettingsBloc, TaxSettingsState>(
      'emits [loading, success] on successful TaxSettingsFetchStarted',
      build: () {
        when(() => mockRepository.getTaxSettings(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => sampleTaxSettings);
        return TaxSettingsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const TaxSettingsFetchStarted()),
      expect: () => [
        const TaxSettingsState(status: TaxSettingsStatus.loading),
        isA<TaxSettingsState>()
            .having((s) => s.status, 'status', TaxSettingsStatus.success)
            .having((s) => s.allSettings.length, 'allSettings.length', 3)
            .having(
                (s) => s.filteredSettings.length, 'filteredSettings.length', 3),
      ],
    );

    blocTest<TaxSettingsBloc, TaxSettingsState>(
      'emits [loading, empty] when store returns empty settings list',
      build: () {
        when(() => mockRepository.getTaxSettings(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => []);
        return TaxSettingsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const TaxSettingsFetchStarted()),
      expect: () => [
        const TaxSettingsState(status: TaxSettingsStatus.loading),
        isA<TaxSettingsState>()
            .having((s) => s.status, 'status', TaxSettingsStatus.empty)
            .having((s) => s.allSettings, 'allSettings', isEmpty),
      ],
    );

    blocTest<TaxSettingsBloc, TaxSettingsState>(
      'emits [loading, failure] on WooCommerceException',
      build: () {
        when(() => mockRepository.getTaxSettings(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenThrow(
          const WooCommerceException(
            message: 'Authentication failed',
            statusCode: 401,
          ),
        );
        return TaxSettingsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const TaxSettingsFetchStarted()),
      expect: () => [
        const TaxSettingsState(status: TaxSettingsStatus.loading),
        isA<TaxSettingsState>()
            .having((s) => s.status, 'status', TaxSettingsStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage',
                'Authentication failed')
            .having((s) => s.errorCode, 'errorCode', 401),
      ],
    );

    blocTest<TaxSettingsBloc, TaxSettingsState>(
      'filters settings on TaxSettingsSearchChanged',
      build: () {
        when(() => mockRepository.getTaxSettings(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => sampleTaxSettings);
        return TaxSettingsBloc(repository: mockRepository);
      },
      act: (bloc) async {
        bloc.add(const TaxSettingsFetchStarted());
        await Future.delayed(const Duration(milliseconds: 10));
        bloc.add(const TaxSettingsSearchChanged('shipping'));
      },
      skip: 2,
      expect: () => [
        isA<TaxSettingsState>()
            .having((s) => s.filteredSettings.length, 'filtered length', 1)
            .having((s) => s.filteredSettings.first.id, 'filtered item id',
                'woocommerce_tax_based_on'),
      ],
    );

    blocTest<TaxSettingsBloc, TaxSettingsState>(
      'filters settings by type on TaxSettingsTypeFilterChanged',
      build: () {
        when(() => mockRepository.getTaxSettings(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => sampleTaxSettings);
        return TaxSettingsBloc(repository: mockRepository);
      },
      act: (bloc) async {
        bloc.add(const TaxSettingsFetchStarted());
        await Future.delayed(const Duration(milliseconds: 10));
        bloc.add(const TaxSettingsTypeFilterChanged('checkbox'));
      },
      skip: 2,
      expect: () => [
        isA<TaxSettingsState>()
            .having((s) => s.filteredSettings.length, 'filtered length', 2)
            .having((s) => s.selectedTypeFilter, 'filter', 'checkbox'),
      ],
    );

    blocTest<TaxSettingsBloc, TaxSettingsState>(
      'deduplicates settings with identical IDs',
      build: () {
        when(() => mockRepository.getTaxSettings(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => [
              sampleTaxSettings[0],
              sampleTaxSettings[0], // Duplicate ID
            ]);
        return TaxSettingsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const TaxSettingsFetchStarted()),
      skip: 1,
      expect: () => [
        isA<TaxSettingsState>()
            .having((s) => s.allSettings.length, 'allSettings.length', 1),
      ],
    );
  });
}
