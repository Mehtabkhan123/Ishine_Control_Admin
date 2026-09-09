import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/coupons/bloc/update_coupon_cubit.dart';
import 'package:ishine_admin_app/features/coupons/bloc/update_coupon_state.dart';
import 'package:ishine_admin_app/features/coupons/data/models/put_update_coupon_model.dart';
import 'package:ishine_admin_app/features/coupons/data/repositories/coupons_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockCouponsRepository extends Mock implements CouponsRepository {}

void main() {
  late MockCouponsRepository mockRepository;

  final sampleUpdatedCoupon = PutUpdateCouponModel(
    id: 555,
    code: 'SAVE25',
    amount: '25.00',
    discountType: 'percent',
    status: 'publish',
  );

  setUp(() {
    mockRepository = MockCouponsRepository();
  });

  group('UpdateCouponCubit', () {
    test('initial state has correct defaults', () {
      final cubit = UpdateCouponCubit(repository: mockRepository);
      expect(cubit.state.status, UpdateCouponStatus.initial);
      expect(cubit.state.updatedCoupon, isNull);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.submittingCouponId, isNull);
      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.isSuccess, isFalse);
      expect(cubit.state.isFailure, isFalse);
    });

    blocTest<UpdateCouponCubit, UpdateCouponState>(
      'emits [submitting, success] when updateCoupon succeeds',
      build: () {
        when(() => mockRepository.updateCoupon(any(), any()))
            .thenAnswer((_) async => sampleUpdatedCoupon);
        return UpdateCouponCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.updateCoupon(
        couponId: 555,
        updateData: {'code': 'SAVE25', 'amount': '25.00'},
      ),
      expect: () => [
        const UpdateCouponState(
          status: UpdateCouponStatus.submitting,
          submittingCouponId: 555,
        ),
        UpdateCouponState(
          status: UpdateCouponStatus.success,
          updatedCoupon: sampleUpdatedCoupon,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.updateCoupon(555, any())).called(1);
      },
    );

    blocTest<UpdateCouponCubit, UpdateCouponState>(
      'emits [submitting, failure] when coupon code already exists (400)',
      build: () {
        when(() => mockRepository.updateCoupon(any(), any())).thenThrow(
          const WooCommerceException(
            message: 'The coupon code already exists',
            statusCode: 400,
          ),
        );
        return UpdateCouponCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.updateCoupon(
        couponId: 555,
        updateData: {'code': 'SAVE25', 'amount': '25.00'},
      ),
      expect: () => [
        const UpdateCouponState(
          status: UpdateCouponStatus.submitting,
          submittingCouponId: 555,
        ),
        const UpdateCouponState(
          status: UpdateCouponStatus.failure,
          errorMessage: 'The coupon code already exists',
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.updateCoupon(555, any())).called(1);
      },
    );

    blocTest<UpdateCouponCubit, UpdateCouponState>(
      'emits [submitting, failure] on network exception',
      build: () {
        when(() => mockRepository.updateCoupon(any(), any())).thenThrow(
          const WooCommerceException(
            message: 'Network connection failed while updating coupon #555.',
          ),
        );
        return UpdateCouponCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.updateCoupon(
        couponId: 555,
        updateData: {'code': 'SAVE25', 'amount': '25.00'},
      ),
      expect: () => [
        const UpdateCouponState(
          status: UpdateCouponStatus.submitting,
          submittingCouponId: 555,
        ),
        const UpdateCouponState(
          status: UpdateCouponStatus.failure,
          errorMessage:
              'Network connection failed while updating coupon #555.',
        ),
      ],
    );

    test('prevents duplicate concurrent submissions while in-flight', () async {
      when(() => mockRepository.updateCoupon(any(), any())).thenAnswer(
        (_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return sampleUpdatedCoupon;
        },
      );

      final cubit = UpdateCouponCubit(repository: mockRepository);

      final call1 = cubit.updateCoupon(
        couponId: 555,
        updateData: {'code': 'SAVE25', 'amount': '25.00'},
      );
      final call2 = cubit.updateCoupon(
        couponId: 555,
        updateData: {'code': 'SAVE25', 'amount': '25.00'},
      );

      final res1 = await call1;
      final res2 = await call2;

      expect(res1, isNotNull);
      expect(res2, isNull); // second call was blocked
      verify(() => mockRepository.updateCoupon(555, any())).called(1);
    });

    test('reset restores initial state', () {
      final cubit = UpdateCouponCubit(repository: mockRepository);
      cubit.emit(UpdateCouponState(
        status: UpdateCouponStatus.success,
        updatedCoupon: sampleUpdatedCoupon,
      ));

      cubit.reset();
      expect(cubit.state.status, UpdateCouponStatus.initial);
      expect(cubit.state.updatedCoupon, isNull);
    });

    test('clearError removes error message', () {
      final cubit = UpdateCouponCubit(repository: mockRepository);
      cubit.emit(const UpdateCouponState(
        status: UpdateCouponStatus.failure,
        errorMessage: 'Something went wrong',
      ));

      cubit.clearError();
      expect(cubit.state.errorMessage, isNull);
    });
  });
}
