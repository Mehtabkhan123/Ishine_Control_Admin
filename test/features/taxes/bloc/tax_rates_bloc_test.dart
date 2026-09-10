import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/taxes/bloc/tax_rates_bloc.dart';
import 'package:ishine_admin_app/features/taxes/bloc/tax_rates_event.dart';
import 'package:ishine_admin_app/features/taxes/bloc/tax_rates_state.dart';
import 'package:ishine_admin_app/features/taxes/data/models/get_tax_rates_model.dart';
import 'package:ishine_admin_app/features/taxes/data/models/post_tax_rates_model.dart';
import 'package:ishine_admin_app/features/taxes/data/repositories/taxes_repository.dart';
import 'package:ishine_admin_app/features/taxes/data/services/taxes_service.dart';
import 'package:mocktail/mocktail.dart';

class MockTaxesRepository extends Mock implements TaxesRepository {}

void main() {
  late MockTaxesRepository mockRepository;

  final sampleRates = [
    GetTaxRatesModel(
      id: 1,
      name: 'Standard VAT',
      rate: '20.0000',
      taxClass: 'standard',
      country: 'GB',
      compound: false,
      shipping: true,
      priority: 1,
    ),
    GetTaxRatesModel(
      id: 2,
      name: 'Reduced VAT',
      rate: '5.0000',
      taxClass: 'reduced-rate',
      country: 'GB',
      compound: false,
      shipping: true,
      priority: 1,
    ),
  ];

  setUp(() {
    mockRepository = MockTaxesRepository();
  });

  group('TaxRatesBloc', () {
    test('initial state has correct default values', () {
      final bloc = TaxRatesBloc(repository: mockRepository);
      expect(bloc.state.status, TaxRatesStatus.initial);
      expect(bloc.state.taxRates, isEmpty);
      expect(bloc.state.currentPage, 1);
      expect(bloc.state.hasReachedMax, false);
      expect(bloc.state.isLoadingMore, false);
      expect(bloc.state.selectedClass, 'all');
      expect(bloc.state.searchQuery, '');
    });

    blocTest<TaxRatesBloc, TaxRatesState>(
      'emits [loading, success] on successful TaxRatesFetchStarted',
      build: () {
        when(() => mockRepository.getTaxRates(
              page: 1,
              perPage: 50,
              taxClass: null,
              search: null,
              forceRefresh: false,
            )).thenAnswer((_) async => TaxRatesResponse(
              taxRates: sampleRates,
              totalTaxRates: 2,
              totalPages: 1,
            ));
        return TaxRatesBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const TaxRatesFetchStarted()),
      expect: () => [
        const TaxRatesState(
          status: TaxRatesStatus.loading,
          currentPage: 1,
          hasReachedMax: false,
        ),
        TaxRatesState(
          status: TaxRatesStatus.success,
          taxRates: sampleRates,
          currentPage: 1,
          hasReachedMax: true,
          totalTaxRates: 2,
          totalPages: 1,
        ),
      ],
    );

    blocTest<TaxRatesBloc, TaxRatesState>(
      'emits [loading, empty] when WooCommerce returns empty tax rates list',
      build: () {
        when(() => mockRepository.getTaxRates(
              page: 1,
              perPage: 50,
              taxClass: null,
              search: null,
              forceRefresh: false,
            )).thenAnswer((_) async => const TaxRatesResponse(
              taxRates: [],
              totalTaxRates: 0,
              totalPages: 1,
            ));
        return TaxRatesBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const TaxRatesFetchStarted()),
      expect: () => [
        const TaxRatesState(
          status: TaxRatesStatus.loading,
          currentPage: 1,
          hasReachedMax: false,
        ),
        const TaxRatesState(
          status: TaxRatesStatus.empty,
          taxRates: [],
          currentPage: 1,
          hasReachedMax: true,
          totalTaxRates: 0,
          totalPages: 1,
        ),
      ],
    );

    blocTest<TaxRatesBloc, TaxRatesState>(
      'emits [loading, failure] on WooCommerceException with error message and code',
      build: () {
        when(() => mockRepository.getTaxRates(
              page: 1,
              perPage: 50,
              taxClass: null,
              search: null,
              forceRefresh: false,
            )).thenThrow(const WooCommerceException(
          message: 'Access forbidden (403). Read permissions required.',
          statusCode: 403,
        ));
        return TaxRatesBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const TaxRatesFetchStarted()),
      expect: () => [
        const TaxRatesState(
          status: TaxRatesStatus.loading,
          currentPage: 1,
          hasReachedMax: false,
        ),
        const TaxRatesState(
          status: TaxRatesStatus.failure,
          errorMessage: 'Access forbidden (403). Read permissions required.',
          errorStatusCode: 403,
        ),
      ],
    );

    blocTest<TaxRatesBloc, TaxRatesState>(
      'deduplicates tax rates with duplicate IDs',
      build: () {
        final duplicated = [
          sampleRates[0],
          sampleRates[0], // Duplicate
          sampleRates[1],
        ];

        when(() => mockRepository.getTaxRates(
              page: 1,
              perPage: 50,
              taxClass: null,
              search: null,
              forceRefresh: false,
            )).thenAnswer((_) async => TaxRatesResponse(
              taxRates: duplicated,
              totalTaxRates: 2,
              totalPages: 1,
            ));
        return TaxRatesBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const TaxRatesFetchStarted()),
      expect: () => [
        const TaxRatesState(
          status: TaxRatesStatus.loading,
          currentPage: 1,
          hasReachedMax: false,
        ),
        TaxRatesState(
          status: TaxRatesStatus.success,
          taxRates: sampleRates,
          currentPage: 1,
          hasReachedMax: true,
          totalTaxRates: 2,
          totalPages: 1,
        ),
      ],
    );

    blocTest<TaxRatesBloc, TaxRatesState>(
      'loads more rates and appends them without duplicates on TaxRatesLoadMore',
      build: () {
        final page2Rates = [
          sampleRates[1], // Duplicate from page 1
          GetTaxRatesModel(
            id: 3,
            name: 'Zero Rate',
            rate: '0.0000',
            taxClass: 'zero-rate',
          ),
        ];

        when(() => mockRepository.getTaxRates(
              page: 2,
              perPage: 50,
              taxClass: null,
              search: null,
            )).thenAnswer((_) async => TaxRatesResponse(
              taxRates: page2Rates,
              totalTaxRates: 3,
              totalPages: 2,
            ));
        return TaxRatesBloc(repository: mockRepository);
      },
      seed: () => TaxRatesState(
        status: TaxRatesStatus.success,
        taxRates: sampleRates,
        currentPage: 1,
        hasReachedMax: false,
        totalTaxRates: 3,
        totalPages: 2,
      ),
      act: (bloc) => bloc.add(const TaxRatesLoadMore()),
      expect: () => [
        TaxRatesState(
          status: TaxRatesStatus.success,
          taxRates: sampleRates,
          currentPage: 1,
          hasReachedMax: false,
          isLoadingMore: true,
          totalTaxRates: 3,
          totalPages: 2,
        ),
        TaxRatesState(
          status: TaxRatesStatus.success,
          taxRates: [
            ...sampleRates,
            GetTaxRatesModel(
              id: 3,
              name: 'Zero Rate',
              rate: '0.0000',
              taxClass: 'zero-rate',
            ),
          ],
          currentPage: 2,
          hasReachedMax: true,
          isLoadingMore: false,
          totalTaxRates: 3,
          totalPages: 2,
        ),
      ],
    );

    blocTest<TaxRatesBloc, TaxRatesState>(
      'prepends new tax rate and increments total count on TaxRatesRateCreated',
      build: () => TaxRatesBloc(repository: mockRepository),
      seed: () => TaxRatesState(
        status: TaxRatesStatus.success,
        taxRates: sampleRates,
        totalTaxRates: 2,
      ),
      act: (bloc) => bloc.add(TaxRatesRateCreated(
        PostTaxRatesModel(
          id: 99,
          name: 'Newly Created Tax',
          rate: '15.0000',
          taxClass: 'standard',
        ),
      )),
      expect: () => [
        TaxRatesState(
          status: TaxRatesStatus.success,
          taxRates: [
            GetTaxRatesModel(
              id: 99,
              name: 'Newly Created Tax',
              rate: '15.0000',
              taxClass: 'standard',
            ),
            ...sampleRates,
          ],
          totalTaxRates: 3,
        ),
      ],
    );
  });
}
