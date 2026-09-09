import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/orders/bloc/update_order_cubit.dart';
import 'package:ishine_admin_app/features/orders/bloc/update_order_state.dart';
import 'package:ishine_admin_app/features/orders/data/models/put_update_order_model.dart';
import 'package:ishine_admin_app/features/orders/data/repositories/orders_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockOrdersRepository extends Mock implements OrdersRepository {}

void main() {
  late MockOrdersRepository mockRepository;

  final sampleUpdatedOrder = PutUpdateOrderModel(
    id: 501,
    status: 'completed',
    customerNote: 'Deliver after 5 PM',
    billing: Billing(firstName: 'Clark', lastName: 'Kent', city: 'Metropolis'),
    shipping: Shipping(firstName: 'Clark', lastName: 'Kent', city: 'Metropolis'),
  );

  setUp(() {
    mockRepository = MockOrdersRepository();
  });

  group('UpdateOrderCubit', () {
    test('initial state has correct defaults', () {
      final cubit = UpdateOrderCubit(repository: mockRepository);
      expect(cubit.state.status, UpdateOrderStatus.initial);
      expect(cubit.state.updatedOrder, isNull);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.submittingOrderId, isNull);
      expect(cubit.state.isSubmitting, false);
      expect(cubit.state.isSuccess, false);
      expect(cubit.state.isFailure, false);
    });

    blocTest<UpdateOrderCubit, UpdateOrderState>(
      'emits [submitting, success] when updateOrder succeeds',
      build: () {
        when(() => mockRepository.updateOrder(
              501,
              any(),
            )).thenAnswer((_) async => sampleUpdatedOrder);
        return UpdateOrderCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.updateOrder(
        orderId: 501,
        updateData: {'status': 'completed'},
      ),
      expect: () => [
        const UpdateOrderState(
          status: UpdateOrderStatus.submitting,
          submittingOrderId: 501,
        ),
        UpdateOrderState(
          status: UpdateOrderStatus.success,
          updatedOrder: sampleUpdatedOrder,
          submittingOrderId: null,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.updateOrder(501, {'status': 'completed'})).called(1);
      },
    );

    blocTest<UpdateOrderCubit, UpdateOrderState>(
      'emits [submitting, failure] when updateOrder encounters an error',
      build: () {
        when(() => mockRepository.updateOrder(
              501,
              any(),
            )).thenThrow(
          const WooCommerceException(
            message: 'Order not found on store.',
            statusCode: 404,
          ),
        );
        return UpdateOrderCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.updateOrder(
        orderId: 501,
        updateData: {'status': 'cancelled'},
      ),
      expect: () => [
        const UpdateOrderState(
          status: UpdateOrderStatus.submitting,
          submittingOrderId: 501,
        ),
        const UpdateOrderState(
          status: UpdateOrderStatus.failure,
          errorMessage: 'Order not found on store.',
          submittingOrderId: null,
        ),
      ],
    );

    test('prevents duplicate concurrent updateOrder requests', () async {
      when(() => mockRepository.updateOrder(
            501,
            any(),
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return sampleUpdatedOrder;
      });

      final cubit = UpdateOrderCubit(repository: mockRepository);

      // Launch first request
      final future1 = cubit.updateOrder(
        orderId: 501,
        updateData: {'status': 'completed'},
      );

      // Immediately launch duplicate second request while first is in-flight
      final future2 = cubit.updateOrder(
        orderId: 501,
        updateData: {'status': 'completed'},
      );

      final result2 = await future2;
      final result1 = await future1;

      expect(result2, isNull); // Second duplicate was blocked
      expect(result1, equals(sampleUpdatedOrder));
      verify(() => mockRepository.updateOrder(501, any())).called(1); // Only called once!
    });

    test('reset clears state back to initial', () {
      final cubit = UpdateOrderCubit(repository: mockRepository);
      cubit.reset();
      expect(cubit.state, const UpdateOrderState());
    });
  });
}
