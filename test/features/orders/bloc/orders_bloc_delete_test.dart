import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/orders/bloc/orders_bloc.dart';
import 'package:ishine_admin_app/features/orders/bloc/orders_event.dart';
import 'package:ishine_admin_app/features/orders/bloc/orders_state.dart';
import 'package:ishine_admin_app/features/orders/data/models/get_orders_model.dart';
import 'package:ishine_admin_app/features/orders/data/repositories/orders_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockOrdersRepository extends Mock implements OrdersRepository {}

void main() {
  late MockOrdersRepository mockRepository;

  final order1 = GET_Orders_Model(id: 101, status: 'processing', number: '101');
  final order2 = GET_Orders_Model(id: 102, status: 'completed', number: '102');

  setUp(() {
    mockRepository = MockOrdersRepository();
  });

  group('OrdersBloc - OrdersOrderDeleted', () {
    blocTest<OrdersBloc, OrdersState>(
      'removes deleted order from list and decrements totalOrders',
      build: () => OrdersBloc(repository: mockRepository),
      seed: () => OrdersState(
        status: OrdersStatus.success,
        orders: [order1, order2],
        totalOrders: 2,
      ),
      act: (bloc) => bloc.add(const OrdersOrderDeleted(101)),
      expect: () => [
        OrdersState(
          status: OrdersStatus.success,
          orders: [order2],
          totalOrders: 1,
        ),
      ],
    );

    blocTest<OrdersBloc, OrdersState>(
      'transitions to empty status when last order is deleted',
      build: () => OrdersBloc(repository: mockRepository),
      seed: () => OrdersState(
        status: OrdersStatus.success,
        orders: [order1],
        totalOrders: 1,
      ),
      act: (bloc) => bloc.add(const OrdersOrderDeleted(101)),
      expect: () => [
        const OrdersState(
          status: OrdersStatus.empty,
          orders: [],
          totalOrders: 0,
        ),
      ],
    );
  });
}
