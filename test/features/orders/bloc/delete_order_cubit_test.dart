import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/orders/bloc/delete_order_cubit.dart';
import 'package:ishine_admin_app/features/orders/bloc/delete_order_state.dart';
import 'package:ishine_admin_app/features/orders/data/models/delete_order_model.dart';
import 'package:ishine_admin_app/features/orders/data/repositories/orders_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockOrdersRepository extends Mock implements OrdersRepository {}

void main() {
  late MockOrdersRepository mockRepository;

  final sampleDeletedOrder = DeleteOrderModel(
    id: 999,
    status: 'trash',
    total: '150.00',
    number: '999',
  );

  setUp(() {
    mockRepository = MockOrdersRepository();
  });

  group('DeleteOrderCubit', () {
    test('initial state has correct defaults', () {
      final cubit = DeleteOrderCubit(repository: mockRepository);
      expect(cubit.state.status, DeleteOrderStatus.initial);
      expect(cubit.state.deletedOrder, isNull);
      expect(cubit.state.deletedOrderId, isNull);
      expect(cubit.state.deletingOrderIds, isEmpty);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.isDeleting, isFalse);
      expect(cubit.state.isSuccess, isFalse);
      expect(cubit.state.isFailure, isFalse);
      expect(cubit.state.isOrderDeleting(999), isFalse);
    });

    blocTest<DeleteOrderCubit, DeleteOrderState>(
      'emits [deleting, success] when deleteOrder succeeds with force=true',
      build: () {
        when(() => mockRepository.deleteOrder(999, force: true))
            .thenAnswer((_) async => sampleDeletedOrder);
        return DeleteOrderCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.deleteOrder(999, force: true),
      expect: () => [
        const DeleteOrderState(
          status: DeleteOrderStatus.deleting,
          deletingOrderIds: {999},
        ),
        DeleteOrderState(
          status: DeleteOrderStatus.success,
          deletedOrder: sampleDeletedOrder,
          deletedOrderId: 999,
          deletingOrderIds: const {},
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.deleteOrder(999, force: true)).called(1);
      },
    );

    blocTest<DeleteOrderCubit, DeleteOrderState>(
      'emits [deleting, failure] when repository throws WooCommerceException',
      build: () {
        when(() => mockRepository.deleteOrder(999, force: true)).thenThrow(
          const WooCommerceException(
            message: 'Order #999 does not exist or has already been deleted.',
            statusCode: 404,
          ),
        );
        return DeleteOrderCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.deleteOrder(999, force: true),
      expect: () => [
        const DeleteOrderState(
          status: DeleteOrderStatus.deleting,
          deletingOrderIds: {999},
        ),
        const DeleteOrderState(
          status: DeleteOrderStatus.failure,
          errorMessage: 'Order #999 does not exist or has already been deleted.',
          deletingOrderIds: {},
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.deleteOrder(999, force: true)).called(1);
      },
    );

    blocTest<DeleteOrderCubit, DeleteOrderState>(
      'emits [deleting, failure] when repository throws network or unexpected exception',
      build: () {
        when(() => mockRepository.deleteOrder(999, force: true)).thenThrow(
          Exception('No internet connection. Please check your network.'),
        );
        return DeleteOrderCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.deleteOrder(999, force: true),
      expect: () => [
        const DeleteOrderState(
          status: DeleteOrderStatus.deleting,
          deletingOrderIds: {999},
        ),
        const DeleteOrderState(
          status: DeleteOrderStatus.failure,
          errorMessage: 'Exception: No internet connection. Please check your network.',
          deletingOrderIds: {},
        ),
      ],
    );

    test('prevents duplicate delete requests while order is already deleting', () async {
      when(() => mockRepository.deleteOrder(999, force: true)).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return sampleDeletedOrder;
      });

      final cubit = DeleteOrderCubit(repository: mockRepository);

      // Trigger first delete call
      final firstFuture = cubit.deleteOrder(999, force: true);

      // Verify that the order is marked as deleting
      expect(cubit.state.isOrderDeleting(999), isTrue);

      // Trigger second duplicate delete call
      final secondResult = await cubit.deleteOrder(999, force: true);
      expect(secondResult, isNull);

      final firstResult = await firstFuture;
      expect(firstResult, equals(sampleDeletedOrder));

      // Ensure mock repository was only called once
      verify(() => mockRepository.deleteOrder(999, force: true)).called(1);
    });

    test('reset clears state back to initial', () {
      final cubit = DeleteOrderCubit(repository: mockRepository);
      cubit.emit(DeleteOrderState(
        status: DeleteOrderStatus.success,
        deletedOrder: sampleDeletedOrder,
        deletedOrderId: 999,
      ));

      expect(cubit.state.isSuccess, isTrue);
      cubit.reset();
      expect(cubit.state.status, DeleteOrderStatus.initial);
      expect(cubit.state.deletedOrder, isNull);
      expect(cubit.state.deletedOrderId, isNull);
    });

    test('clearError removes error message from state', () {
      final cubit = DeleteOrderCubit(repository: mockRepository);
      cubit.emit(const DeleteOrderState(
        status: DeleteOrderStatus.failure,
        errorMessage: 'Something went wrong',
      ));

      expect(cubit.state.errorMessage, 'Something went wrong');
      cubit.clearError();
      expect(cubit.state.errorMessage, isNull);
    });
  });
}
