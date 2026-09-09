import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/customers/bloc/delete_customer_cubit.dart';
import 'package:ishine_admin_app/features/customers/bloc/delete_customer_state.dart';
import 'package:ishine_admin_app/features/customers/data/models/delete_customer_model.dart';
import 'package:ishine_admin_app/features/customers/data/repositories/customers_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockCustomersRepository extends Mock implements CustomersRepository {}

void main() {
  late MockCustomersRepository mockRepository;

  final sampleDeletedCustomer = DeleteCustomerModel(
    id: 99,
    firstName: 'Alice',
    lastName: 'Smith',
    email: 'alice.smith@example.com',
    role: 'customer',
  );

  setUp(() {
    mockRepository = MockCustomersRepository();
  });

  group('DeleteCustomerCubit', () {
    test('initial state has correct defaults', () {
      final cubit = DeleteCustomerCubit(repository: mockRepository);
      expect(cubit.state.status, DeleteCustomerStatus.initial);
      expect(cubit.state.deletedCustomer, isNull);
      expect(cubit.state.deletedCustomerId, isNull);
      expect(cubit.state.deletingCustomerIds, isEmpty);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.isDeleting, isFalse);
      expect(cubit.state.isSuccess, isFalse);
      expect(cubit.state.isFailure, isFalse);
      expect(cubit.state.isCustomerDeleting(99), isFalse);
    });

    blocTest<DeleteCustomerCubit, DeleteCustomerState>(
      'emits [deleting, success] when deleteCustomer succeeds with force=true',
      build: () {
        when(() => mockRepository.deleteCustomer(
              99,
              force: true,
            )).thenAnswer((_) async => sampleDeletedCustomer);
        return DeleteCustomerCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.deleteCustomer(99, force: true),
      expect: () => [
        const DeleteCustomerState(
          status: DeleteCustomerStatus.deleting,
          deletingCustomerIds: {99},
        ),
        DeleteCustomerState(
          status: DeleteCustomerStatus.success,
          deletedCustomer: sampleDeletedCustomer,
          deletedCustomerId: 99,
          deletingCustomerIds: const {},
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.deleteCustomer(99, force: true)).called(1);
      },
    );

    blocTest<DeleteCustomerCubit, DeleteCustomerState>(
      'emits [deleting, failure] when customer does not exist (404)',
      build: () {
        when(() => mockRepository.deleteCustomer(
              404,
              force: true,
            )).thenThrow(
          const WooCommerceException(
            message: 'Customer #404 does not exist or has already been deleted.',
            statusCode: 404,
          ),
        );
        return DeleteCustomerCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.deleteCustomer(404, force: true),
      expect: () => [
        const DeleteCustomerState(
          status: DeleteCustomerStatus.deleting,
          deletingCustomerIds: {404},
        ),
        const DeleteCustomerState(
          status: DeleteCustomerStatus.failure,
          errorMessage: 'Customer #404 does not exist or has already been deleted.',
          deletingCustomerIds: {},
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.deleteCustomer(404, force: true)).called(1);
      },
    );

    blocTest<DeleteCustomerCubit, DeleteCustomerState>(
      'emits [deleting, failure] on network error',
      build: () {
        when(() => mockRepository.deleteCustomer(
              99,
              force: true,
            )).thenThrow(
          const WooCommerceException(
            message: 'Network connection failed while deleting customer #99.',
          ),
        );
        return DeleteCustomerCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.deleteCustomer(99, force: true),
      expect: () => [
        const DeleteCustomerState(
          status: DeleteCustomerStatus.deleting,
          deletingCustomerIds: {99},
        ),
        const DeleteCustomerState(
          status: DeleteCustomerStatus.failure,
          errorMessage: 'Network connection failed while deleting customer #99.',
          deletingCustomerIds: {},
        ),
      ],
    );

    test('prevents duplicate delete requests for same customer in-flight', () async {
      when(() => mockRepository.deleteCustomer(
            99,
            force: true,
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return sampleDeletedCustomer;
      });

      final cubit = DeleteCustomerCubit(repository: mockRepository);

      // Trigger first request
      final future1 = cubit.deleteCustomer(99, force: true);
      expect(cubit.state.isCustomerDeleting(99), isTrue);

      // Trigger second duplicate request while first is in-flight
      final future2 = cubit.deleteCustomer(99, force: true);

      final result2 = await future2;
      expect(result2, isNull); // Rejected duplicate

      final result1 = await future1;
      expect(result1?.id, 99);
      expect(cubit.state.status, DeleteCustomerStatus.success);
      verify(() => mockRepository.deleteCustomer(99, force: true)).called(1);
    });

    test('reset restores initial state', () {
      final cubit = DeleteCustomerCubit(repository: mockRepository);
      cubit.reset();
      expect(cubit.state, const DeleteCustomerState());
    });

    test('clearError removes error message', () {
      final cubit = DeleteCustomerCubit(repository: mockRepository);
      cubit.emit(const DeleteCustomerState(
        status: DeleteCustomerStatus.failure,
        errorMessage: 'Some error',
      ));
      expect(cubit.state.errorMessage, 'Some error');
      cubit.clearError();
      expect(cubit.state.errorMessage, isNull);
    });
  });
}
