import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/customers/bloc/update_customer_cubit.dart';
import 'package:ishine_admin_app/features/customers/bloc/update_customer_state.dart';
import 'package:ishine_admin_app/features/customers/data/models/put_update_customer_model.dart';
import 'package:ishine_admin_app/features/customers/data/repositories/customers_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockCustomersRepository extends Mock implements CustomersRepository {}

void main() {
  late MockCustomersRepository mockRepository;

  final sampleUpdatedCustomer = PutUpdateCustomerModel(
    id: 123,
    firstName: 'Sarah',
    lastName: 'Connor',
    email: 'sarah.connor@example.com',
    role: 'customer',
    billing: Billing(firstName: 'Sarah', lastName: 'Connor', city: 'LA'),
    shipping: Shipping(firstName: 'Sarah', lastName: 'Connor', city: 'LA'),
  );

  setUp(() {
    mockRepository = MockCustomersRepository();
  });

  group('UpdateCustomerCubit', () {
    test('initial state has correct defaults', () {
      final cubit = UpdateCustomerCubit(repository: mockRepository);
      expect(cubit.state.status, UpdateCustomerStatus.initial);
      expect(cubit.state.updatedCustomer, isNull);
      expect(cubit.state.submittingCustomerId, isNull);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.isSuccess, isFalse);
      expect(cubit.state.isFailure, isFalse);
    });

    blocTest<UpdateCustomerCubit, UpdateCustomerState>(
      'emits [submitting, success] when updateCustomer succeeds',
      build: () {
        when(() => mockRepository.updateCustomer(
              123,
              any(),
            )).thenAnswer((_) async => sampleUpdatedCustomer);
        return UpdateCustomerCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.updateCustomer(
        customerId: 123,
        updateData: {'first_name': 'Sarah', 'last_name': 'Connor'},
      ),
      expect: () => [
        const UpdateCustomerState(
          status: UpdateCustomerStatus.submitting,
          submittingCustomerId: 123,
        ),
        UpdateCustomerState(
          status: UpdateCustomerStatus.success,
          updatedCustomer: sampleUpdatedCustomer,
          submittingCustomerId: null,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.updateCustomer(123, any())).called(1);
      },
    );

    blocTest<UpdateCustomerCubit, UpdateCustomerState>(
      'emits [submitting, failure] when updateCustomer encounters WooCommerceException',
      build: () {
        when(() => mockRepository.updateCustomer(
              123,
              any(),
            )).thenThrow(
          const WooCommerceException(
            message: 'Email address is invalid.',
            statusCode: 400,
          ),
        );
        return UpdateCustomerCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.updateCustomer(
        customerId: 123,
        updateData: {'email': 'invalid-email'},
      ),
      expect: () => [
        const UpdateCustomerState(
          status: UpdateCustomerStatus.submitting,
          submittingCustomerId: 123,
        ),
        const UpdateCustomerState(
          status: UpdateCustomerStatus.failure,
          errorMessage: 'Email address is invalid.',
          submittingCustomerId: null,
        ),
      ],
    );

    blocTest<UpdateCustomerCubit, UpdateCustomerState>(
      'emits [submitting, failure] when updateCustomer encounters generic Exception',
      build: () {
        when(() => mockRepository.updateCustomer(
              123,
              any(),
            )).thenThrow(Exception('Network timeout'));
        return UpdateCustomerCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.updateCustomer(
        customerId: 123,
        updateData: {},
      ),
      expect: () => [
        const UpdateCustomerState(
          status: UpdateCustomerStatus.submitting,
          submittingCustomerId: 123,
        ),
        const UpdateCustomerState(
          status: UpdateCustomerStatus.failure,
          errorMessage: 'Exception: Network timeout',
          submittingCustomerId: null,
        ),
      ],
    );

    test('prevents duplicate concurrent updateCustomer requests', () async {
      when(() => mockRepository.updateCustomer(123, any())).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return sampleUpdatedCustomer;
      });

      final cubit = UpdateCustomerCubit(repository: mockRepository);

      final firstFuture = cubit.updateCustomer(
        customerId: 123,
        updateData: {'first_name': 'Sarah'},
      );

      expect(cubit.state.isSubmitting, isTrue);

      final secondResult = await cubit.updateCustomer(
        customerId: 123,
        updateData: {'first_name': 'Duplicate'},
      );
      expect(secondResult, isNull);

      final firstResult = await firstFuture;
      expect(firstResult, equals(sampleUpdatedCustomer));

      verify(() => mockRepository.updateCustomer(123, any())).called(1);
    });

    test('reset clears state back to initial', () {
      final cubit = UpdateCustomerCubit(repository: mockRepository);
      cubit.emit(UpdateCustomerState(
        status: UpdateCustomerStatus.success,
        updatedCustomer: sampleUpdatedCustomer,
      ));

      expect(cubit.state.isSuccess, isTrue);
      cubit.reset();
      expect(cubit.state.status, UpdateCustomerStatus.initial);
      expect(cubit.state.updatedCustomer, isNull);
    });

    test('clearError removes error message from state', () {
      final cubit = UpdateCustomerCubit(repository: mockRepository);
      cubit.emit(const UpdateCustomerState(
        status: UpdateCustomerStatus.failure,
        errorMessage: 'Something broke',
      ));

      expect(cubit.state.errorMessage, 'Something broke');
      cubit.clearError();
      expect(cubit.state.errorMessage, isNull);
    });
  });
}
