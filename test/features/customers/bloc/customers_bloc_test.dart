import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/customers/bloc/customers_bloc.dart';
import 'package:ishine_admin_app/features/customers/bloc/customers_event.dart';
import 'package:ishine_admin_app/features/customers/bloc/customers_state.dart';
import 'package:ishine_admin_app/features/customers/data/models/get_customers_model.dart';
import 'package:ishine_admin_app/features/customers/data/repositories/customers_repository.dart';
import 'package:ishine_admin_app/features/customers/data/services/customers_service.dart';
import 'package:mocktail/mocktail.dart';

class MockCustomersRepository extends Mock implements CustomersRepository {}

void main() {
  late MockCustomersRepository mockRepository;

  final sampleCustomers = [
    GETCustomersModel(
      id: 1,
      firstName: 'Alice',
      lastName: 'Smith',
      email: 'alice@example.com',
      username: 'alicesmith',
      role: 'customer',
      isPayingCustomer: true,
      dateCreated: '2026-03-01T10:00:00',
    ),
    GETCustomersModel(
      id: 2,
      firstName: 'Bob',
      lastName: 'Jones',
      email: 'bob@example.com',
      username: 'bobjones',
      role: 'customer',
      isPayingCustomer: false,
      dateCreated: '2026-02-15T12:00:00',
    ),
  ];

  setUp(() {
    mockRepository = MockCustomersRepository();
  });

  group('CustomersBloc', () {
    test('initial state has correct defaults', () {
      final bloc = CustomersBloc(repository: mockRepository);
      expect(bloc.state.status, CustomersStatus.initial);
      expect(bloc.state.customers, isEmpty);
      expect(bloc.state.currentPage, 1);
      expect(bloc.state.hasReachedMax, false);
      expect(bloc.state.isLoadingMore, false);
      expect(bloc.state.selectedRole, 'all');
      expect(bloc.state.searchQuery, '');
    });

    blocTest<CustomersBloc, CustomersState>(
      'emits [loading, success] when CustomersFetchStarted succeeds with data',
      build: () {
        when(() => mockRepository.getCustomers(
              page: 1,
              perPage: 20,
              orderby: 'registered_date',
              order: 'desc',
              role: null,
              search: null,
            )).thenAnswer((_) async => CustomersResponse(
              customers: sampleCustomers,
              totalCustomers: 2,
              totalPages: 1,
            ));
        return CustomersBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const CustomersFetchStarted()),
      expect: () => [
        const CustomersState(
          status: CustomersStatus.loading,
          currentPage: 1,
          hasReachedMax: false,
        ),
        CustomersState(
          status: CustomersStatus.success,
          customers: sampleCustomers,
          currentPage: 1,
          hasReachedMax: true,
          totalCustomers: 2,
          totalPages: 1,
        ),
      ],
    );

    blocTest<CustomersBloc, CustomersState>(
      'emits [loading, empty] when CustomersFetchStarted returns no customers',
      build: () {
        when(() => mockRepository.getCustomers(
              page: 1,
              perPage: 20,
              orderby: 'registered_date',
              order: 'desc',
              role: null,
              search: null,
            )).thenAnswer((_) async => const CustomersResponse(
              customers: [],
              totalCustomers: 0,
              totalPages: 1,
            ));
        return CustomersBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const CustomersFetchStarted()),
      expect: () => [
        const CustomersState(
          status: CustomersStatus.loading,
          currentPage: 1,
          hasReachedMax: false,
        ),
        const CustomersState(
          status: CustomersStatus.empty,
          customers: [],
          currentPage: 1,
          hasReachedMax: true,
          totalCustomers: 0,
          totalPages: 1,
        ),
      ],
    );

    blocTest<CustomersBloc, CustomersState>(
      'emits [loading, failure] when CustomersFetchStarted throws WooCommerceException',
      build: () {
        when(() => mockRepository.getCustomers(
              page: 1,
              perPage: 20,
              orderby: 'registered_date',
              order: 'desc',
              role: null,
              search: null,
            )).thenThrow(const WooCommerceException(message: 'Authentication failed'));
        return CustomersBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const CustomersFetchStarted()),
      expect: () => [
        const CustomersState(
          status: CustomersStatus.loading,
          currentPage: 1,
          hasReachedMax: false,
        ),
        const CustomersState(
          status: CustomersStatus.failure,
          errorMessage: 'Authentication failed',
        ),
      ],
    );

    blocTest<CustomersBloc, CustomersState>(
      'prevents duplicate customers on CustomersLoadMore',
      build: () {
        final page2Customers = [
          // Duplicate customer with ID 2
          GETCustomersModel(
            id: 2,
            firstName: 'Bob Duplicate',
            lastName: 'Jones',
            email: 'bob@example.com',
          ),
          // New customer with ID 3
          GETCustomersModel(
            id: 3,
            firstName: 'Charlie',
            lastName: 'Brown',
            email: 'charlie@example.com',
          ),
        ];

        when(() => mockRepository.getCustomers(
              page: 2,
              perPage: 20,
              orderby: 'registered_date',
              order: 'desc',
              role: null,
              search: null,
            )).thenAnswer((_) async => CustomersResponse(
              customers: page2Customers,
              totalCustomers: 3,
              totalPages: 2,
            ));

        return CustomersBloc(repository: mockRepository);
      },
      seed: () => CustomersState(
        status: CustomersStatus.success,
        customers: sampleCustomers,
        currentPage: 1,
        hasReachedMax: false,
        totalCustomers: 3,
        totalPages: 2,
      ),
      act: (bloc) => bloc.add(const CustomersLoadMore()),
      verify: (bloc) {
        // Only customer with ID 3 should be added; ID 2 was already present
        expect(bloc.state.customers.length, 3);
        expect(bloc.state.customers.map((c) => c.id).toList(), [1, 2, 3]);
        expect(bloc.state.currentPage, 2);
        expect(bloc.state.hasReachedMax, true);
      },
    );

    blocTest<CustomersBloc, CustomersState>(
      'resets and loads role filter on CustomersRoleFilterChanged',
      build: () {
        when(() => mockRepository.getCustomers(
              page: 1,
              perPage: 20,
              orderby: 'registered_date',
              order: 'desc',
              role: 'administrator',
              search: null,
            )).thenAnswer((_) async => CustomersResponse(
              customers: [sampleCustomers.first],
              totalCustomers: 1,
              totalPages: 1,
            ));
        return CustomersBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const CustomersRoleFilterChanged('administrator')),
      expect: () => [
        const CustomersState(
          status: CustomersStatus.loading,
          selectedRole: 'administrator',
          currentPage: 1,
          hasReachedMax: false,
        ),
        CustomersState(
          status: CustomersStatus.success,
          customers: [sampleCustomers.first],
          selectedRole: 'administrator',
          currentPage: 1,
          hasReachedMax: true,
          totalCustomers: 1,
          totalPages: 1,
        ),
      ],
    );

    blocTest<CustomersBloc, CustomersState>(
      'filters by search query on CustomersSearchChanged',
      build: () {
        when(() => mockRepository.getCustomers(
              page: 1,
              perPage: 20,
              orderby: 'registered_date',
              order: 'desc',
              role: null,
              search: 'Alice',
            )).thenAnswer((_) async => CustomersResponse(
              customers: [sampleCustomers.first],
              totalCustomers: 1,
              totalPages: 1,
            ));
        return CustomersBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const CustomersSearchChanged('Alice')),
      expect: () => [
        const CustomersState(
          status: CustomersStatus.loading,
          searchQuery: 'Alice',
          currentPage: 1,
          hasReachedMax: false,
        ),
        CustomersState(
          status: CustomersStatus.success,
          customers: [sampleCustomers.first],
          searchQuery: 'Alice',
          currentPage: 1,
          hasReachedMax: true,
          totalCustomers: 1,
          totalPages: 1,
        ),
      ],
    );
  });
}
