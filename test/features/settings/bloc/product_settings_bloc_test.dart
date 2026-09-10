import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/settings/bloc/product_settings_bloc.dart';
import 'package:ishine_admin_app/features/settings/bloc/product_settings_event.dart';
import 'package:ishine_admin_app/features/settings/bloc/product_settings_state.dart';
import 'package:ishine_admin_app/features/settings/data/models/get_product_settings_model.dart';
import 'package:ishine_admin_app/features/settings/data/repositories/product_settings_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockProductSettingsRepository extends Mock
    implements ProductSettingsRepository {}

void main() {
  late MockProductSettingsRepository mockRepository;

  final sampleProductSettings = [
    GetProductSettingsModel(
      id: 'woocommerce_weight_unit',
      label: 'Weight unit',
      description: 'Weight measurement unit.',
      type: 'select',
      value: 'kg',
    ),
    GetProductSettingsModel(
      id: 'woocommerce_manage_stock',
      label: 'Manage stock',
      type: 'checkbox',
      value: 'yes',
    ),
    GetProductSettingsModel(
      id: 'woocommerce_hold_stock_minutes',
      label: 'Hold stock (minutes)',
      type: 'number',
      value: 60,
    ),
  ];

  setUp(() {
    mockRepository = MockProductSettingsRepository();
  });

  group('ProductSettingsBloc', () {
    test('initial state has correct default values', () {
      final bloc = ProductSettingsBloc(repository: mockRepository);
      expect(bloc.state.status, ProductSettingsStatus.initial);
      expect(bloc.state.allSettings, isEmpty);
      expect(bloc.state.filteredSettings, isEmpty);
      expect(bloc.state.searchQuery, '');
      expect(bloc.state.selectedTypeFilter, isNull);
    });

    blocTest<ProductSettingsBloc, ProductSettingsState>(
      'emits [loading, success] on successful ProductSettingsFetchStarted',
      build: () {
        when(() => mockRepository.getProductSettings(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => sampleProductSettings);
        return ProductSettingsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const ProductSettingsFetchStarted()),
      expect: () => [
        const ProductSettingsState(status: ProductSettingsStatus.loading),
        isA<ProductSettingsState>()
            .having((s) => s.status, 'status', ProductSettingsStatus.success)
            .having((s) => s.allSettings.length, 'allSettings.length', 3)
            .having((s) => s.filteredSettings.length, 'filteredSettings.length', 3),
      ],
    );

    blocTest<ProductSettingsBloc, ProductSettingsState>(
      'emits [loading, empty] when store returns empty settings list',
      build: () {
        when(() => mockRepository.getProductSettings(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => []);
        return ProductSettingsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const ProductSettingsFetchStarted()),
      expect: () => [
        const ProductSettingsState(status: ProductSettingsStatus.loading),
        isA<ProductSettingsState>()
            .having((s) => s.status, 'status', ProductSettingsStatus.empty)
            .having((s) => s.allSettings, 'allSettings', isEmpty),
      ],
    );

    blocTest<ProductSettingsBloc, ProductSettingsState>(
      'emits [loading, failure] on WooCommerceException',
      build: () {
        when(() => mockRepository.getProductSettings(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenThrow(
          const WooCommerceException(
            message: 'Authentication failed',
            statusCode: 401,
          ),
        );
        return ProductSettingsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const ProductSettingsFetchStarted()),
      expect: () => [
        const ProductSettingsState(status: ProductSettingsStatus.loading),
        const ProductSettingsState(
          status: ProductSettingsStatus.failure,
          errorMessage: 'Authentication failed',
          errorCode: 401,
        ),
      ],
    );

    blocTest<ProductSettingsBloc, ProductSettingsState>(
      'filters settings on ProductSettingsSearchChanged',
      build: () {
        when(() => mockRepository.getProductSettings(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => sampleProductSettings);
        return ProductSettingsBloc(repository: mockRepository);
      },
      seed: () => ProductSettingsState(
        status: ProductSettingsStatus.success,
        allSettings: sampleProductSettings,
        filteredSettings: sampleProductSettings,
      ),
      act: (bloc) => bloc.add(const ProductSettingsSearchChanged('weight')),
      expect: () => [
        isA<ProductSettingsState>()
            .having((s) => s.searchQuery, 'searchQuery', 'weight')
            .having((s) => s.filteredSettings.length, 'filteredSettings.length', 1)
            .having((s) => s.filteredSettings.first.id, 'id', 'woocommerce_weight_unit'),
      ],
    );

    blocTest<ProductSettingsBloc, ProductSettingsState>(
      'filters settings by type on ProductSettingsTypeFilterChanged',
      build: () {
        when(() => mockRepository.getProductSettings(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => sampleProductSettings);
        return ProductSettingsBloc(repository: mockRepository);
      },
      seed: () => ProductSettingsState(
        status: ProductSettingsStatus.success,
        allSettings: sampleProductSettings,
        filteredSettings: sampleProductSettings,
      ),
      act: (bloc) => bloc.add(const ProductSettingsTypeFilterChanged('checkbox')),
      expect: () => [
        isA<ProductSettingsState>()
            .having((s) => s.selectedTypeFilter, 'typeFilter', 'checkbox')
            .having((s) => s.filteredSettings.length, 'filteredSettings.length', 1)
            .having((s) => s.filteredSettings.first.id, 'id', 'woocommerce_manage_stock'),
      ],
    );

    blocTest<ProductSettingsBloc, ProductSettingsState>(
      'deduplicates settings with identical IDs',
      build: () {
        final duplicateList = [
          GetProductSettingsModel(id: 'dup_prod', label: 'First Product Setting'),
          GetProductSettingsModel(id: 'dup_prod', label: 'Duplicate Product Setting'),
        ];
        when(() => mockRepository.getProductSettings(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => duplicateList);
        return ProductSettingsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const ProductSettingsFetchStarted()),
      expect: () => [
        const ProductSettingsState(status: ProductSettingsStatus.loading),
        isA<ProductSettingsState>()
            .having((s) => s.status, 'status', ProductSettingsStatus.success)
            .having((s) => s.allSettings.length, 'allSettings.length', 1)
            .having((s) => s.allSettings.first.label, 'label', 'First Product Setting'),
      ],
    );
  });
}
