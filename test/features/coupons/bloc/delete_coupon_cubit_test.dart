import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/coupons/bloc/delete_coupon_cubit.dart';
import 'package:ishine_admin_app/features/coupons/bloc/delete_coupon_state.dart';
import 'package:ishine_admin_app/features/coupons/data/models/delete_coupon_model.dart';
import 'package:ishine_admin_app/features/coupons/data/repositories/coupons_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockCouponsRepository extends Mock implements CouponsRepository {}

void main() {
  late MockCouponsRepository mockRepository;

  final sampleDeletedCoupon = DeleteCouponModel(
    id: 555,
    code: 'DELETE555',
    amount: '15.00',
    discountType: 'percent',
    status: 'publish',
  );

  setUp(() {
    mockRepository = MockCouponsRepository();
  });

  group('DeleteCouponCubit', () {
    test('initial state has correct defaults', () {
      final cubit = DeleteCouponCubit(repository: mockRepository);
      expect(cubit.state.status, DeleteCouponStatus.initial);
      expect(cubit.state.deletedCoupon, isNull);
      expect(cubit.state.deletedCouponId, isNull);
      expect(cubit.state.deletingCouponIds, isEmpty);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.isDeleting, isFalse);
      expect(cubit.state.isSuccess, isFalse);
      expect(cubit.state.isFailure, isFalse);
      expect(cubit.state.isCouponDeleting(555), isFalse);
    });

    blocTest<DeleteCouponCubit, DeleteCouponState>(
      'emits [deleting, success] when deleteCoupon succeeds with force=true',
      build: () {
        when(() => mockRepository.deleteCoupon(
              555,
              force: true,
            )).thenAnswer((_) async => sampleDeletedCoupon);
        return DeleteCouponCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.deleteCoupon(555, force: true),
      expect: () => [
        const DeleteCouponState(
          status: DeleteCouponStatus.deleting,
          deletingCouponIds: {555},
        ),
        DeleteCouponState(
          status: DeleteCouponStatus.success,
          deletedCoupon: sampleDeletedCoupon,
          deletedCouponId: 555,
          deletingCouponIds: const {},
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.deleteCoupon(555, force: true)).called(1);
      },
    );

    blocTest<DeleteCouponCubit, DeleteCouponState>(
      'emits [deleting, failure] when coupon does not exist (404)',
      build: () {
        when(() => mockRepository.deleteCoupon(
              404,
              force: true,
            )).thenThrow(
          const WooCommerceException(
            message: 'Coupon #404 does not exist or has already been deleted.',
            statusCode: 404,
          ),
        );
        return DeleteCouponCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.deleteCoupon(404, force: true),
      expect: () => [
        const DeleteCouponState(
          status: DeleteCouponStatus.deleting,
          deletingCouponIds: {404},
        ),
        const DeleteCouponState(
          status: DeleteCouponStatus.failure,
          errorMessage:
              'Coupon #404 does not exist or has already been deleted.',
          deletingCouponIds: {},
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.deleteCoupon(404, force: true)).called(1);
      },
    );

    blocTest<DeleteCouponCubit, DeleteCouponState>(
      'emits [deleting, failure] on network error',
      build: () {
        when(() => mockRepository.deleteCoupon(
              555,
              force: true,
            )).thenThrow(
          const WooCommerceException(
            message: 'Network connection failed while deleting coupon #555.',
          ),
        );
        return DeleteCouponCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.deleteCoupon(555, force: true),
      expect: () => [
        const DeleteCouponState(
          status: DeleteCouponStatus.deleting,
          deletingCouponIds: {555},
        ),
        const DeleteCouponState(
          status: DeleteCouponStatus.failure,
          errorMessage:
              'Network connection failed while deleting coupon #555.',
          deletingCouponIds: {},
        ),
      ],
    );

    test('prevents duplicate delete requests while the same couponId is in-flight',
        () async {
      when(() => mockRepository.deleteCoupon(
            555,
            force: true,
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return sampleDeletedCoupon;
      });

      final cubit = DeleteCouponCubit(repository: mockRepository);

      final call1 = cubit.deleteCoupon(555, force: true);
      final call2 = cubit.deleteCoupon(555, force: true); // duplicate call

      final res1 = await call1;
      final res2 = await call2;

      expect(res1, isNotNull);
      expect(res2, isNull); // second call was blocked

      verify(() => mockRepository.deleteCoupon(555, force: true)).called(1);
    });

    test('reset restores initial state', () {
      final cubit = DeleteCouponCubit(repository: mockRepository);
      cubit.emit(DeleteCouponState(
        status: DeleteCouponStatus.success,
        deletedCoupon: sampleDeletedCoupon,
        deletedCouponId: 555,
      ));

      cubit.reset();
      expect(cubit.state.status, DeleteCouponStatus.initial);
      expect(cubit.state.deletedCoupon, isNull);
      expect(cubit.state.deletedCouponId, isNull);
    });

    test('clearError removes error message', () {
      final cubit = DeleteCouponCubit(repository: mockRepository);
      cubit.emit(const DeleteCouponState(
        status: DeleteCouponStatus.failure,
        errorMessage: 'Network error',
      ));

      cubit.clearError();
      expect(cubit.state.errorMessage, isNull);
    });
  });
}
