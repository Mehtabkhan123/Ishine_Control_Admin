import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/coupons/bloc/coupons_bloc.dart';
import 'package:ishine_admin_app/features/coupons/bloc/coupons_event.dart';
import 'package:ishine_admin_app/features/coupons/bloc/coupons_state.dart';
import 'package:ishine_admin_app/features/coupons/data/models/get_coupon_report_model.dart';
import 'package:ishine_admin_app/features/coupons/data/repositories/coupons_repository.dart';
import 'package:ishine_admin_app/features/coupons/data/services/coupons_service.dart';
import 'package:mocktail/mocktail.dart';

class MockCouponsRepository extends Mock implements CouponsRepository {}

void main() {
  late MockCouponsRepository mockRepository;

  final sampleCoupons = [
    GETCouponReportModel(
      id: 1,
      code: 'WELCOME10',
      amount: '10.00',
      discountType: 'percent',
      status: 'publish',
      usageCount: 12,
      freeShipping: false,
    ),
    GETCouponReportModel(
      id: 2,
      code: 'FREESHIP',
      amount: '0.00',
      discountType: 'fixed_cart',
      status: 'publish',
      usageCount: 5,
      freeShipping: true,
    ),
  ];

  setUp(() {
    mockRepository = MockCouponsRepository();
  });

  group('CouponsBloc', () {
    test('initial state has correct default values', () {
      final bloc = CouponsBloc(repository: mockRepository);
      expect(bloc.state.status, CouponsStatus.initial);
      expect(bloc.state.coupons, isEmpty);
      expect(bloc.state.currentPage, 1);
      expect(bloc.state.hasReachedMax, false);
      expect(bloc.state.isLoadingMore, false);
      expect(bloc.state.selectedType, 'all');
      expect(bloc.state.searchQuery, '');
    });

    blocTest<CouponsBloc, CouponsState>(
      'emits [loading, success] on successful CouponsFetchStarted',
      build: () {
        when(() => mockRepository.getCoupons(
              page: 1,
              perPage: 50,
              search: null,
              discountType: null,
            )).thenAnswer((_) async => CouponsResponse(
              coupons: sampleCoupons,
              totalCoupons: 2,
              totalPages: 1,
            ));
        return CouponsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const CouponsFetchStarted()),
      expect: () => [
        const CouponsState(
          status: CouponsStatus.loading,
          currentPage: 1,
          hasReachedMax: false,
        ),
        CouponsState(
          status: CouponsStatus.success,
          coupons: sampleCoupons,
          currentPage: 1,
          hasReachedMax: true,
          totalCoupons: 2,
          totalPages: 1,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.getCoupons(
              page: 1,
              perPage: 50,
              search: null,
              discountType: null,
            )).called(1);
      },
    );

    blocTest<CouponsBloc, CouponsState>(
      'emits [loading, failure] when CouponsFetchStarted encounters network error',
      build: () {
        when(() => mockRepository.getCoupons(
              page: 1,
              perPage: 50,
              search: null,
              discountType: null,
            )).thenThrow(
          const WooCommerceException(
            statusCode: 500,
            message: 'Internal Server Error',
          ),
        );
        return CouponsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const CouponsFetchStarted()),
      expect: () => [
        const CouponsState(
          status: CouponsStatus.loading,
          currentPage: 1,
          hasReachedMax: false,
        ),
        isA<CouponsState>()
            .having((s) => s.status, 'status', CouponsStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', isNotEmpty),
      ],
    );

    blocTest<CouponsBloc, CouponsState>(
      'loads page 2 and deduplicates items on CouponsLoadMore',
      build: () {
        final page2Coupons = [
          // Duplicate of id 2
          GETCouponReportModel(
            id: 2,
            code: 'FREESHIP',
            amount: '0.00',
            discountType: 'fixed_cart',
            status: 'publish',
          ),
          // New coupon
          GETCouponReportModel(
            id: 3,
            code: 'VIP50',
            amount: '50.00',
            discountType: 'fixed_cart',
            status: 'publish',
          ),
        ];

        when(() => mockRepository.getCoupons(
              page: 2,
              perPage: 50,
              search: null,
              discountType: null,
            )).thenAnswer((_) async => CouponsResponse(
              coupons: page2Coupons,
              totalCoupons: 3,
              totalPages: 2,
            ));
        return CouponsBloc(repository: mockRepository);
      },
      seed: () => CouponsState(
        status: CouponsStatus.success,
        coupons: sampleCoupons,
        currentPage: 1,
        totalPages: 2,
        hasReachedMax: false,
      ),
      act: (bloc) => bloc.add(const CouponsLoadMore()),
      expect: () => [
        CouponsState(
          status: CouponsStatus.success,
          coupons: sampleCoupons,
          currentPage: 1,
          totalPages: 2,
          hasReachedMax: false,
          isLoadingMore: true,
        ),
        isA<CouponsState>()
            .having((s) => s.status, 'status', CouponsStatus.success)
            .having((s) => s.currentPage, 'currentPage', 2)
            .having((s) => s.hasReachedMax, 'hasReachedMax', true)
            .having((s) => s.isLoadingMore, 'isLoadingMore', false)
            .having((s) => s.coupons.length, 'coupons count without dupes', 3)
            .having((s) => s.coupons.map((c) => c.id).toList(), 'ids', [1, 2, 3]),
      ],
      verify: (_) {
        verify(() => mockRepository.getCoupons(
              page: 2,
              perPage: 50,
              search: null,
              discountType: null,
            )).called(1);
      },
    );

    blocTest<CouponsBloc, CouponsState>(
      'ignores CouponsLoadMore when hasReachedMax is true',
      build: () => CouponsBloc(repository: mockRepository),
      seed: () => CouponsState(
        status: CouponsStatus.success,
        coupons: sampleCoupons,
        currentPage: 1,
        hasReachedMax: true,
      ),
      act: (bloc) => bloc.add(const CouponsLoadMore()),
      expect: () => [],
      verify: (_) {
        verifyNever(() => mockRepository.getCoupons(
              page: any(named: 'page'),
              perPage: any(named: 'perPage'),
            ));
      },
    );

    blocTest<CouponsBloc, CouponsState>(
      'ignores CouponsLoadMore when isLoadingMore is already true',
      build: () => CouponsBloc(repository: mockRepository),
      seed: () => CouponsState(
        status: CouponsStatus.success,
        coupons: sampleCoupons,
        currentPage: 1,
        isLoadingMore: true,
        hasReachedMax: false,
      ),
      act: (bloc) => bloc.add(const CouponsLoadMore()),
      expect: () => [],
    );

    blocTest<CouponsBloc, CouponsState>(
      'resets and filters by discountType on CouponsTypeFilterChanged',
      build: () {
        when(() => mockRepository.getCoupons(
              page: 1,
              perPage: 50,
              search: null,
              discountType: 'percent',
            )).thenAnswer((_) async => CouponsResponse(
              coupons: [sampleCoupons.first],
              totalCoupons: 1,
              totalPages: 1,
            ));
        return CouponsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const CouponsTypeFilterChanged('percent')),
      expect: () => [
        const CouponsState(
          status: CouponsStatus.loading,
          selectedType: 'percent',
          currentPage: 1,
        ),
        CouponsState(
          status: CouponsStatus.success,
          coupons: [sampleCoupons.first],
          selectedType: 'percent',
          currentPage: 1,
          hasReachedMax: true,
          totalCoupons: 1,
          totalPages: 1,
        ),
      ],
    );

    blocTest<CouponsBloc, CouponsState>(
      'refreshes list and preserves state on CouponsRefreshed',
      build: () {
        when(() => mockRepository.getCoupons(
              page: 1,
              perPage: 50,
              search: null,
              discountType: null,
            )).thenAnswer((_) async => CouponsResponse(
              coupons: sampleCoupons,
              totalCoupons: 2,
              totalPages: 1,
            ));
        return CouponsBloc(repository: mockRepository);
      },
      seed: () => CouponsState(
        status: CouponsStatus.success,
        coupons: [sampleCoupons.first],
        currentPage: 1,
      ),
      act: (bloc) => bloc.add(const CouponsRefreshed()),
      expect: () => [
        CouponsState(
          status: CouponsStatus.success,
          coupons: sampleCoupons,
          currentPage: 1,
          hasReachedMax: true,
          totalCoupons: 2,
          totalPages: 1,
        ),
      ],
    );
  });
}
