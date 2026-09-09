import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/customers/bloc/single_customer_cubit.dart';
import 'package:ishine_admin_app/features/customers/bloc/single_customer_state.dart';
import 'package:ishine_admin_app/features/customers/data/models/get_customers_model.dart';
import 'package:ishine_admin_app/features/customers/data/models/get_single_customers_model.dart';
import 'package:ishine_admin_app/features/customers/data/repositories/customers_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockCustomersRepository extends Mock implements CustomersRepository {}

void main() {
  late MockCustomersRepository mockRepository;

  final testCustomer = GETSingleCustomersModel(
    id: 10,
    firstName: 'Diana',
    lastName: 'Prince',
    email: 'diana@themyscira.com',
    username: 'wonderwoman',
    role: 'customer',
    isPayingCustomer: true,
    billing: Billing(
      firstName: 'Diana',
      lastName: 'Prince',
      city: 'Washington',
      country: 'US',
      phone: '+1 202-555-0188',
    ),
  );

  setUp(() {
    mockRepository = MockCustomersRepository();
  });

  group('SingleCustomerCubit', () {
    test('initial state has correct defaults', () {
      final cubit = SingleCustomerCubit(repository: mockRepository);
      expect(cubit.state.status, SingleCustomerStatus.initial);
      expect(cubit.state.customer, isNull);
      expect(cubit.state.activeCustomerId, isNull);
      expect(cubit.state.cachedCustomers, isEmpty);
      expect(cubit.state.loadingCustomerIds, isEmpty);
      expect(cubit.state.activeSectionIndex, 0);
    });

    blocTest<SingleCustomerCubit, SingleCustomerState>(
      'emits [loading, success] when fetchSingleCustomer succeeds',
      build: () {
        when(() => mockRepository.getSingleCustomer(10))
            .thenAnswer((_) async => testCustomer);
        return SingleCustomerCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.fetchSingleCustomer(10),
      expect: () => [
        const SingleCustomerState(
          status: SingleCustomerStatus.loading,
          activeCustomerId: 10,
          customer: null,
          loadingCustomerIds: {10},
        ),
        SingleCustomerState(
          status: SingleCustomerStatus.success,
          activeCustomerId: 10,
          customer: testCustomer,
          cachedCustomers: {10: testCustomer},
          loadingCustomerIds: const {},
        ),
      ],
    );

    blocTest<SingleCustomerCubit, SingleCustomerState>(
      'returns cached customer immediately without network request if already cached',
      build: () => SingleCustomerCubit(repository: mockRepository),
      seed: () => SingleCustomerState(
        status: SingleCustomerStatus.success,
        activeCustomerId: 10,
        customer: testCustomer,
        cachedCustomers: {10: testCustomer},
      ),
      act: (cubit) => cubit.fetchSingleCustomer(10),
      expect: () => [],
      verify: (_) {
        verifyNever(() => mockRepository.getSingleCustomer(10));
      },
    );

    blocTest<SingleCustomerCubit, SingleCustomerState>(
      'performs network request when forceRefresh: true even if already cached',
      build: () {
        when(() => mockRepository.getSingleCustomer(10))
            .thenAnswer((_) async => testCustomer);
        return SingleCustomerCubit(repository: mockRepository);
      },
      seed: () => SingleCustomerState(
        status: SingleCustomerStatus.success,
        activeCustomerId: 10,
        customer: testCustomer,
        cachedCustomers: {10: testCustomer},
      ),
      act: (cubit) => cubit.fetchSingleCustomer(10, forceRefresh: true),
      expect: () => [
        SingleCustomerState(
          status: SingleCustomerStatus.loading,
          activeCustomerId: 10,
          customer: testCustomer,
          cachedCustomers: {10: testCustomer},
          loadingCustomerIds: const {10},
        ),
        SingleCustomerState(
          status: SingleCustomerStatus.success,
          activeCustomerId: 10,
          customer: testCustomer,
          cachedCustomers: {10: testCustomer},
          loadingCustomerIds: const {},
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.getSingleCustomer(10)).called(1);
      },
    );

    blocTest<SingleCustomerCubit, SingleCustomerState>(
      'prevents duplicate requests when the same customerId is already in-flight',
      build: () => SingleCustomerCubit(repository: mockRepository),
      seed: () => const SingleCustomerState(
        status: SingleCustomerStatus.loading,
        activeCustomerId: 10,
        loadingCustomerIds: {10},
      ),
      act: (cubit) => cubit.fetchSingleCustomer(10),
      expect: () => [],
      verify: (_) {
        verifyNever(() => mockRepository.getSingleCustomer(10));
      },
    );

    blocTest<SingleCustomerCubit, SingleCustomerState>(
      'emits [loading, failure] when network request throws WooCommerceException',
      build: () {
        when(() => mockRepository.getSingleCustomer(99))
            .thenThrow(const WooCommerceException(message: 'Customer not found'));
        return SingleCustomerCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.fetchSingleCustomer(99),
      expect: () => [
        const SingleCustomerState(
          status: SingleCustomerStatus.loading,
          activeCustomerId: 99,
          customer: null,
          loadingCustomerIds: {99},
        ),
        const SingleCustomerState(
          status: SingleCustomerStatus.failure,
          activeCustomerId: 99,
          errorMessage: 'Customer not found',
          loadingCustomerIds: {},
        ),
      ],
    );

    test('setInitialCustomer sets state immediately with GETCustomersModel', () {
      final cubit = SingleCustomerCubit(repository: mockRepository);
      final listCustomer = GETCustomersModel(
        id: 55,
        firstName: 'Barry',
        lastName: 'Allen',
        email: 'barry@starlabs.com',
      );

      cubit.setInitialCustomer(listCustomer);

      expect(cubit.state.status, SingleCustomerStatus.success);
      expect(cubit.state.activeCustomerId, 55);
      expect(cubit.state.customer?.displayName, 'Barry Allen');
      expect(cubit.state.cachedCustomers[55]?.email, 'barry@starlabs.com');
    });

    test('setActiveSection updates activeSectionIndex', () {
      final cubit = SingleCustomerCubit(repository: mockRepository);
      cubit.setActiveSection(2);
      expect(cubit.state.activeSectionIndex, 2);
    });
  });
}
