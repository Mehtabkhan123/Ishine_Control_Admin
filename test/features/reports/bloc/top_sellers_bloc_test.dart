import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/reports/bloc/top_sellers_bloc.dart';
import 'package:ishine_admin_app/features/reports/bloc/top_sellers_event.dart';
import 'package:ishine_admin_app/features/reports/bloc/top_sellers_state.dart';
import 'package:ishine_admin_app/features/reports/data/models/top_seller_model.dart';
import 'package:ishine_admin_app/features/reports/data/repositories/reports_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockReportsRepository extends Mock implements ReportsRepository {}

void main() {
  late MockReportsRepository mockRepository;
  late List<TopSellerModel> mockItems;

  setUpAll(() {
    dotenv.testLoad(mergeWith: {
      'WOOCOMMERCE_BASE_URL': 'https://example.com',
      'WOOCOMMERCE_CONSUMER_KEY': 'ck_test',
      'WOOCOMMERCE_CONSUMER_SECRET': 'cs_test',
    });
  });

  setUp(() {
    mockRepository = MockReportsRepository();
    mockItems = [
      TopSellerModel(
        name: 'USB To Lightning AAA 1M Data Cable',
        productId: 51768,
        quantity: 5463,
      ),
      TopSellerModel(
        name: 'ANG TC15A Single USB Power Adaptor 1A',
        productId: 36197,
        quantity: 2417,
      ),
    ];
  });

  group('TopSellersBloc', () {
    test('initial state is TopSellersInitial with period month', () {
      final bloc = TopSellersBloc(repository: mockRepository);
      expect(bloc.state, const TopSellersInitial());
      expect(bloc.state.period, 'month');
      bloc.close();
    });

    blocTest<TopSellersBloc, TopSellersState>(
      'emits [TopSellersLoading, TopSellersSuccess] when fetch succeeds with items',
      build: () {
        when(() => mockRepository.getTopSellers(
              period: any(named: 'period'),
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => mockItems);
        return TopSellersBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const TopSellersFetchRequested()),
      expect: () => [
        isA<TopSellersLoading>().having((s) => s.period, 'period', 'month'),
        isA<TopSellersSuccess>()
            .having((s) => s.period, 'period', 'month')
            .having((s) => s.items.length, 'items count', 2)
            .having((s) => s.totalQuantitySold, 'total units', 7880),
      ],
      verify: (_) {
        verify(() => mockRepository.getTopSellers(period: 'month', forceRefresh: false)).called(1);
      },
    );

    blocTest<TopSellersBloc, TopSellersState>(
      'emits [TopSellersLoading, TopSellersEmpty] when fetch returns empty list',
      build: () {
        when(() => mockRepository.getTopSellers(
              period: any(named: 'period'),
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => []);
        return TopSellersBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const TopSellersFetchRequested()),
      expect: () => [
        isA<TopSellersLoading>().having((s) => s.period, 'period', 'month'),
        isA<TopSellersEmpty>().having((s) => s.period, 'period', 'month'),
      ],
    );

    blocTest<TopSellersBloc, TopSellersState>(
      'emits [TopSellersLoading, TopSellersFailure] on network error',
      build: () {
        when(() => mockRepository.getTopSellers(
              period: any(named: 'period'),
              forceRefresh: any(named: 'forceRefresh'),
            )).thenThrow(
          const WooCommerceException(message: 'Could not connect to the WooCommerce store. Network error.'),
        );
        return TopSellersBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const TopSellersFetchRequested()),
      expect: () => [
        isA<TopSellersLoading>(),
        isA<TopSellersFailure>()
            .having((s) => s.isNetworkError, 'isNetworkError', isTrue)
            .having((s) => s.isTimeout, 'isTimeout', isFalse)
            .having((s) => s.errorMessage, 'errorMessage', contains('Could not connect')),
      ],
    );

    blocTest<TopSellersBloc, TopSellersState>(
      'emits [TopSellersLoading, TopSellersFailure] on timeout error',
      build: () {
        when(() => mockRepository.getTopSellers(
              period: any(named: 'period'),
              forceRefresh: any(named: 'forceRefresh'),
            )).thenThrow(
          const WooCommerceException(message: 'Request timed out', statusCode: 408),
        );
        return TopSellersBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const TopSellersFetchRequested()),
      expect: () => [
        isA<TopSellersLoading>(),
        isA<TopSellersFailure>()
            .having((s) => s.isTimeout, 'isTimeout', isTrue)
            .having((s) => s.isNetworkError, 'isNetworkError', isFalse),
      ],
    );

    blocTest<TopSellersBloc, TopSellersState>(
      'prevents duplicate API call when fetch requested and already in success state for same period',
      build: () {
        when(() => mockRepository.getTopSellers(
              period: any(named: 'period'),
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => mockItems);
        return TopSellersBloc(repository: mockRepository);
      },
      seed: () => TopSellersSuccess(
        items: mockItems,
        period: 'month',
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const TopSellersFetchRequested()),
      expect: () => [],
      verify: (_) {
        verifyNever(() => mockRepository.getTopSellers(
              period: any(named: 'period'),
              forceRefresh: any(named: 'forceRefresh'),
            ));
      },
    );

    blocTest<TopSellersBloc, TopSellersState>(
      'forces fresh fetch on TopSellersRefreshRequested',
      build: () {
        when(() => mockRepository.getTopSellers(
              period: any(named: 'period'),
              forceRefresh: true,
            )).thenAnswer((_) async => mockItems);
        return TopSellersBloc(repository: mockRepository);
      },
      seed: () => TopSellersSuccess(
        items: mockItems,
        period: 'month',
        lastUpdated: DateTime(2026, 1, 1),
      ),
      act: (bloc) => bloc.add(const TopSellersRefreshRequested()),
      expect: () => [
        isA<TopSellersLoading>(),
        isA<TopSellersSuccess>(),
      ],
      verify: (_) {
        verify(() => mockRepository.getTopSellers(period: 'month', forceRefresh: true)).called(1);
      },
    );

    blocTest<TopSellersBloc, TopSellersState>(
      'updates period and queries fresh data on TopSellersPeriodChanged',
      build: () {
        when(() => mockRepository.getTopSellers(
              period: 'year',
              forceRefresh: false,
            )).thenAnswer((_) async => mockItems);
        return TopSellersBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const TopSellersPeriodChanged('year')),
      expect: () => [
        isA<TopSellersLoading>().having((s) => s.period, 'period', 'year'),
        isA<TopSellersSuccess>().having((s) => s.period, 'period', 'year'),
      ],
      verify: (_) {
        verify(() => mockRepository.getTopSellers(period: 'year', forceRefresh: false)).called(1);
      },
    );
  });
}
