import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/settings/bloc/general_settings_bloc.dart';
import 'package:ishine_admin_app/features/settings/bloc/general_settings_event.dart';
import 'package:ishine_admin_app/features/settings/bloc/general_settings_state.dart';
import 'package:ishine_admin_app/features/settings/data/models/get_general_settings_model.dart';
import 'package:ishine_admin_app/features/settings/data/repositories/general_settings_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockGeneralSettingsRepository extends Mock
    implements GeneralSettingsRepository {}

void main() {
  late MockGeneralSettingsRepository mockRepository;

  final sampleSettings = [
    GetGeneralSettingsModel(
      id: 'woocommerce_store_address',
      label: 'Address line 1',
      description: 'The street address for your business location.',
      type: 'text',
      value: '123 Market St',
    ),
    GetGeneralSettingsModel(
      id: 'woocommerce_calc_taxes',
      label: 'Enable taxes',
      type: 'checkbox',
      value: 'yes',
    ),
    GetGeneralSettingsModel(
      id: 'woocommerce_currency',
      label: 'Currency',
      type: 'select',
      value: 'USD',
    ),
  ];

  setUp(() {
    mockRepository = MockGeneralSettingsRepository();
  });

  group('GeneralSettingsBloc', () {
    test('initial state has correct default values', () {
      final bloc = GeneralSettingsBloc(repository: mockRepository);
      expect(bloc.state.status, GeneralSettingsStatus.initial);
      expect(bloc.state.allSettings, isEmpty);
      expect(bloc.state.filteredSettings, isEmpty);
      expect(bloc.state.searchQuery, '');
      expect(bloc.state.selectedTypeFilter, isNull);
    });

    blocTest<GeneralSettingsBloc, GeneralSettingsState>(
      'emits [loading, success] on successful GeneralSettingsFetchStarted',
      build: () {
        when(() => mockRepository.getGeneralSettings(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => sampleSettings);
        return GeneralSettingsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const GeneralSettingsFetchStarted()),
      expect: () => [
        const GeneralSettingsState(status: GeneralSettingsStatus.loading),
        isA<GeneralSettingsState>()
            .having((s) => s.status, 'status', GeneralSettingsStatus.success)
            .having((s) => s.allSettings.length, 'allSettings.length', 3)
            .having((s) => s.filteredSettings.length, 'filteredSettings.length', 3),
      ],
    );

    blocTest<GeneralSettingsBloc, GeneralSettingsState>(
      'emits [loading, empty] when store returns empty settings list',
      build: () {
        when(() => mockRepository.getGeneralSettings(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => []);
        return GeneralSettingsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const GeneralSettingsFetchStarted()),
      expect: () => [
        const GeneralSettingsState(status: GeneralSettingsStatus.loading),
        isA<GeneralSettingsState>()
            .having((s) => s.status, 'status', GeneralSettingsStatus.empty)
            .having((s) => s.allSettings, 'allSettings', isEmpty),
      ],
    );

    blocTest<GeneralSettingsBloc, GeneralSettingsState>(
      'emits [loading, failure] on WooCommerceException',
      build: () {
        when(() => mockRepository.getGeneralSettings(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenThrow(
          const WooCommerceException(
            message: 'Authentication failed',
            statusCode: 401,
          ),
        );
        return GeneralSettingsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const GeneralSettingsFetchStarted()),
      expect: () => [
        const GeneralSettingsState(status: GeneralSettingsStatus.loading),
        const GeneralSettingsState(
          status: GeneralSettingsStatus.failure,
          errorMessage: 'Authentication failed',
          errorCode: 401,
        ),
      ],
    );

    blocTest<GeneralSettingsBloc, GeneralSettingsState>(
      'filters settings on GeneralSettingsSearchChanged',
      build: () {
        when(() => mockRepository.getGeneralSettings(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => sampleSettings);
        return GeneralSettingsBloc(repository: mockRepository);
      },
      seed: () => GeneralSettingsState(
        status: GeneralSettingsStatus.success,
        allSettings: sampleSettings,
        filteredSettings: sampleSettings,
      ),
      act: (bloc) => bloc.add(const GeneralSettingsSearchChanged('currency')),
      expect: () => [
        isA<GeneralSettingsState>()
            .having((s) => s.searchQuery, 'searchQuery', 'currency')
            .having((s) => s.filteredSettings.length, 'filteredSettings.length', 1)
            .having((s) => s.filteredSettings.first.id, 'id', 'woocommerce_currency'),
      ],
    );

    blocTest<GeneralSettingsBloc, GeneralSettingsState>(
      'filters settings by type on GeneralSettingsTypeFilterChanged',
      build: () {
        when(() => mockRepository.getGeneralSettings(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => sampleSettings);
        return GeneralSettingsBloc(repository: mockRepository);
      },
      seed: () => GeneralSettingsState(
        status: GeneralSettingsStatus.success,
        allSettings: sampleSettings,
        filteredSettings: sampleSettings,
      ),
      act: (bloc) => bloc.add(const GeneralSettingsTypeFilterChanged('checkbox')),
      expect: () => [
        isA<GeneralSettingsState>()
            .having((s) => s.selectedTypeFilter, 'typeFilter', 'checkbox')
            .having((s) => s.filteredSettings.length, 'filteredSettings.length', 1)
            .having((s) => s.filteredSettings.first.id, 'id', 'woocommerce_calc_taxes'),
      ],
    );

    blocTest<GeneralSettingsBloc, GeneralSettingsState>(
      'deduplicates settings with identical IDs',
      build: () {
        final duplicateList = [
          GetGeneralSettingsModel(id: 'dup_id', label: 'First'),
          GetGeneralSettingsModel(id: 'dup_id', label: 'Second Duplicate'),
        ];
        when(() => mockRepository.getGeneralSettings(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => duplicateList);
        return GeneralSettingsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const GeneralSettingsFetchStarted()),
      expect: () => [
        const GeneralSettingsState(status: GeneralSettingsStatus.loading),
        isA<GeneralSettingsState>()
            .having((s) => s.status, 'status', GeneralSettingsStatus.success)
            .having((s) => s.allSettings.length, 'allSettings.length', 1)
            .having((s) => s.allSettings.first.label, 'label', 'First'),
      ],
    );
  });
}
