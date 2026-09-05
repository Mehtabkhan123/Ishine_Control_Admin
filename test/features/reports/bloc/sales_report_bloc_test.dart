import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/reports/bloc/sales_report_bloc.dart';
import 'package:ishine_admin_app/features/reports/bloc/sales_report_event.dart';
import 'package:ishine_admin_app/features/reports/bloc/sales_report_state.dart';
import 'package:ishine_admin_app/features/reports/data/models/sales_report_model.dart';
import 'package:ishine_admin_app/features/reports/data/repositories/reports_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockReportsRepository extends Mock implements ReportsRepository {}

void main() {
  late MockReportsRepository mockRepository;
  late GetSalesReportModel mockModel;

  setUpAll(() {
    dotenv.testLoad(mergeWith: {
      'WOOCOMMERCE_BASE_URL': 'https://example.com',
      'WOOCOMMERCE_CONSUMER_KEY': 'ck_test',
      'WOOCOMMERCE_CONSUMER_SECRET': 'cs_test',
    });
  });

  setUp(() {
    mockRepository = MockReportsRepository();
    mockModel = GetSalesReportModel(
      totalSales: '12500.50',
      netSales: '11200.00',
      averageSales: '416.68',
      totalOrders: 30,
      totalItems: 58,
      totalTax: '850.25',
      totalShipping: '450.25',
      totalRefunds: 2,
      totalDiscount: '150.00',
      totalsGroupedBy: 'day',
      totalCustomers: 28,
      totals: {
        '2026-09-01': DailyTotal(
          sales: '450.00',
          orders: 2,
          items: 3,
          tax: '30.00',
          shipping: '15.00',
          discount: '0.00',
          customers: 2,
        ),
      },
    );
  });

  group('SalesReportBloc', () {
    test('initial state is SalesReportInitial with default period month', () {
      final bloc = SalesReportBloc(repository: mockRepository);
      expect(bloc.state, const SalesReportInitial());
      expect(bloc.state.period, 'month');
      bloc.close();
    });

    blocTest<SalesReportBloc, SalesReportState>(
      'emits [SalesReportLoading, SalesReportSuccess] when fetch succeeds',
      build: () {
        when(() => mockRepository.getSalesReport(
              period: any(named: 'period'),
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => mockModel);
        return SalesReportBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const SalesReportFetchRequested()),
      expect: () => [
        isA<SalesReportLoading>().having((s) => s.period, 'period', 'month'),
        isA<SalesReportSuccess>()
            .having((s) => s.period, 'period', 'month')
            .having((s) => s.report?.totalSales, 'totalSales', '12500.50')
            .having((s) => s.report?.totalOrders, 'totalOrders', 30),
      ],
      verify: (_) {
        verify(() => mockRepository.getSalesReport(period: 'month', forceRefresh: false)).called(1);
      },
    );

    blocTest<SalesReportBloc, SalesReportState>(
      'emits [SalesReportLoading, SalesReportEmpty] when report is empty or null',
      build: () {
        when(() => mockRepository.getSalesReport(
              period: any(named: 'period'),
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => null);
        return SalesReportBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const SalesReportFetchRequested()),
      expect: () => [
        isA<SalesReportLoading>(),
        isA<SalesReportEmpty>().having((s) => s.period, 'period', 'month'),
      ],
    );

    blocTest<SalesReportBloc, SalesReportState>(
      'emits [SalesReportLoading, SalesReportFailure] on network error',
      build: () {
        when(() => mockRepository.getSalesReport(
              period: any(named: 'period'),
              forceRefresh: any(named: 'forceRefresh'),
            )).thenThrow(
          const WooCommerceException(message: 'Could not connect to the WooCommerce store. Network error.'),
        );
        return SalesReportBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const SalesReportFetchRequested()),
      expect: () => [
        isA<SalesReportLoading>(),
        isA<SalesReportFailure>()
            .having((s) => s.isNetworkError, 'isNetworkError', isTrue)
            .having((s) => s.isTimeout, 'isTimeout', isFalse)
            .having((s) => s.errorMessage, 'errorMessage', contains('Could not connect')),
      ],
    );

    blocTest<SalesReportBloc, SalesReportState>(
      'emits [SalesReportLoading, SalesReportFailure] on timeout error',
      build: () {
        when(() => mockRepository.getSalesReport(
              period: any(named: 'period'),
              forceRefresh: any(named: 'forceRefresh'),
            )).thenThrow(
          const WooCommerceException(message: 'Connection timed out', statusCode: 408),
        );
        return SalesReportBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const SalesReportFetchRequested()),
      expect: () => [
        isA<SalesReportLoading>(),
        isA<SalesReportFailure>()
            .having((s) => s.isTimeout, 'isTimeout', isTrue)
            .having((s) => s.isNetworkError, 'isNetworkError', isFalse),
      ],
    );

    blocTest<SalesReportBloc, SalesReportState>(
      'prevents duplicate API call when fetch requested and state is already success with same period',
      build: () {
        when(() => mockRepository.getSalesReport(
              period: any(named: 'period'),
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => mockModel);
        return SalesReportBloc(repository: mockRepository);
      },
      seed: () => SalesReportSuccess(
        report: mockModel,
        period: 'month',
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const SalesReportFetchRequested()),
      expect: () => [],
      verify: (_) {
        verifyNever(() => mockRepository.getSalesReport(
              period: any(named: 'period'),
              forceRefresh: any(named: 'forceRefresh'),
            ));
      },
    );

    blocTest<SalesReportBloc, SalesReportState>(
      'forces fresh fetch on SalesReportRefreshRequested',
      build: () {
        when(() => mockRepository.getSalesReport(
              period: any(named: 'period'),
              forceRefresh: true,
            )).thenAnswer((_) async => mockModel);
        return SalesReportBloc(repository: mockRepository);
      },
      seed: () => SalesReportSuccess(
        report: mockModel,
        period: 'month',
        lastUpdated: DateTime(2026, 1, 1),
      ),
      act: (bloc) => bloc.add(const SalesReportRefreshRequested()),
      expect: () => [
        isA<SalesReportLoading>(),
        isA<SalesReportSuccess>(),
      ],
      verify: (_) {
        verify(() => mockRepository.getSalesReport(period: 'month', forceRefresh: true)).called(1);
      },
    );

    blocTest<SalesReportBloc, SalesReportState>(
      'updates period and triggers fetch on SalesReportPeriodChanged',
      build: () {
        when(() => mockRepository.getSalesReport(
              period: 'year',
              forceRefresh: false,
            )).thenAnswer((_) async => mockModel);
        return SalesReportBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const SalesReportPeriodChanged('year')),
      expect: () => [
        isA<SalesReportLoading>().having((s) => s.period, 'period', 'year'),
        isA<SalesReportSuccess>().having((s) => s.period, 'period', 'year'),
      ],
      verify: (_) {
        verify(() => mockRepository.getSalesReport(period: 'year', forceRefresh: false)).called(1);
      },
    );
  });
}
