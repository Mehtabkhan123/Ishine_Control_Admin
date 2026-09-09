import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/coupons/bloc/create_coupon_cubit.dart';
import 'package:ishine_admin_app/features/coupons/bloc/create_coupon_state.dart';
import 'package:ishine_admin_app/features/coupons/data/models/post_create_coupon_model.dart';
import 'package:ishine_admin_app/features/coupons/data/repositories/coupons_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockCouponsRepository extends Mock implements CouponsRepository {}

void main() {
  late MockCouponsRepository mockRepository;

  final sampleCreatedCoupon = PostCreateCouponModel(
    id: 555,
    code: 'SAVE20',
    amount: '20.00',
    discountType: 'percent',
    status: 'publish',
  );

  setUp(() {
    mockRepository = MockCouponsRepository();
  });

  group('CreateCouponCubit', () {
    test('initial state has correct defaults', () {
      final cubit = CreateCouponCubit(repository: mockRepository);
      expect(cubit.state.status, CreateCouponStatus.initial);
      expect(cubit.state.createdCoupon, isNull);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.isSuccess, isFalse);
      expect(cubit.state.isFailure, isFalse);
    });

    blocTest<CreateCouponCubit, CreateCouponState>(
      'emits [submitting, success] when createCoupon succeeds',
      build: () {
        when(() => mockRepository.createCoupon(any()))
            .thenAnswer((_) async => sampleCreatedCoupon);
        return CreateCouponCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.createCoupon({'code': 'SAVE20', 'amount': '20.00'}),
      expect: () => [
        const CreateCouponState(
          status: CreateCouponStatus.submitting,
        ),
        CreateCouponState(
          status: CreateCouponStatus.success,
          createdCoupon: sampleCreatedCoupon,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.createCoupon(any())).called(1);
      },
    );

    blocTest<CreateCouponCubit, CreateCouponState>(
      'emits [submitting, failure] when coupon code already exists (400)',
      build: () {
        when(() => mockRepository.createCoupon(any())).thenThrow(
          const WooCommerceException(
            message: 'The coupon code already exists',
            statusCode: 400,
          ),
        );
        return CreateCouponCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.createCoupon({'code': 'SAVE20', 'amount': '20.00'}),
      expect: () => [
        const CreateCouponState(
          status: CreateCouponStatus.submitting,
        ),
        const CreateCouponState(
          status: CreateCouponStatus.failure,
          errorMessage: 'The coupon code already exists',
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.createCoupon(any())).called(1);
      },
    );

    blocTest<CreateCouponCubit, CreateCouponState>(
      'emits [submitting, failure] on network exception',
      build: () {
        when(() => mockRepository.createCoupon(any())).thenThrow(
          const WooCommerceException(
            message: 'Network connection failed while creating coupon.',
          ),
        );
        return CreateCouponCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.createCoupon({'code': 'SAVE20', 'amount': '20.00'}),
      expect: () => [
        const CreateCouponState(
          status: CreateCouponStatus.submitting,
        ),
        const CreateCouponState(
          status: CreateCouponStatus.failure,
          errorMessage: 'Network connection failed while creating coupon.',
        ),
      ],
    );

    test('prevents duplicate concurrent submissions while in-flight', () async {
      when(() => mockRepository.createCoupon(any())).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return sampleCreatedCoupon;
      });

      final cubit = CreateCouponCubit(repository: mockRepository);

      // Start first request
      final future1 = cubit.createCoupon({'code': 'SAVE20'});
      expect(cubit.state.isSubmitting, isTrue);

      // Trigger duplicate submission while first is still running
      final future2 = cubit.createCoupon({'code': 'SAVE20'});

      final result2 = await future2;
      expect(result2, isNull); // Duplicate was rejected

      final result1 = await future1;
      expect(result1?.id, 555);
      expect(cubit.state.status, CreateCouponStatus.success);

      verify(() => mockRepository.createCoupon(any())).called(1);
    });

    test('reset restores initial state', () {
      final cubit = CreateCouponCubit(repository: mockRepository);
      cubit.reset();
      expect(cubit.state, const CreateCouponState());
    });

    test('clearError removes error message', () {
      final cubit = CreateCouponCubit(repository: mockRepository);
      cubit.emit(const CreateCouponState(
        status: CreateCouponStatus.failure,
        errorMessage: 'Invalid discount amount',
      ));
      expect(cubit.state.errorMessage, 'Invalid discount amount');
      cubit.clearError();
      expect(cubit.state.errorMessage, isNull);
    });
  });
}
