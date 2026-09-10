import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/payment_gateways/bloc/payment_gateways_bloc.dart';
import 'package:ishine_admin_app/features/payment_gateways/bloc/payment_gateways_event.dart';
import 'package:ishine_admin_app/features/payment_gateways/bloc/payment_gateways_state.dart';
import 'package:ishine_admin_app/features/payment_gateways/data/models/get_payment_gateways_model.dart';
import 'package:ishine_admin_app/features/payment_gateways/data/repositories/payment_gateways_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockPaymentGatewaysRepository extends Mock
    implements PaymentGatewaysRepository {}

void main() {
  late MockPaymentGatewaysRepository mockRepository;

  final sampleGateways = [
    GetPaymentGatewaysModel(
      id: 'bacs',
      title: 'Direct Bank Transfer',
      enabled: true,
      methodTitle: 'Direct bank transfer',
      order: 1,
    ),
    GetPaymentGatewaysModel(
      id: 'cod',
      title: 'Cash on Delivery',
      enabled: false,
      methodTitle: 'Cash on delivery',
      needsSetup: true,
      order: 2,
    ),
  ];

  setUp(() {
    mockRepository = MockPaymentGatewaysRepository();
  });

  group('PaymentGatewaysBloc', () {
    test('initial state has correct default values', () {
      final bloc = PaymentGatewaysBloc(repository: mockRepository);
      expect(bloc.state.status, PaymentGatewaysStatus.initial);
      expect(bloc.state.gateways, isEmpty);
      expect(bloc.state.searchQuery, '');
      expect(bloc.state.selectedFilter, 'all');
      expect(bloc.state.isLoading, false);
      expect(bloc.state.isSuccess, false);
      expect(bloc.state.isEmpty, false);
      expect(bloc.state.isFailure, false);
    });

    blocTest<PaymentGatewaysBloc, PaymentGatewaysState>(
      'emits [loading, success] on successful PaymentGatewaysFetchStarted',
      build: () {
        when(() => mockRepository.getPaymentGateways(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => sampleGateways);
        return PaymentGatewaysBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const PaymentGatewaysFetchStarted()),
      expect: () => [
        const PaymentGatewaysState(
          status: PaymentGatewaysStatus.loading,
        ),
        PaymentGatewaysState(
          status: PaymentGatewaysStatus.success,
          gateways: sampleGateways,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.getPaymentGateways(forceRefresh: false))
            .called(1);
      },
    );

    blocTest<PaymentGatewaysBloc, PaymentGatewaysState>(
      'emits [loading, empty] when store returns empty payment gateways list',
      build: () {
        when(() => mockRepository.getPaymentGateways(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => []);
        return PaymentGatewaysBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const PaymentGatewaysFetchStarted()),
      expect: () => [
        const PaymentGatewaysState(
          status: PaymentGatewaysStatus.loading,
        ),
        const PaymentGatewaysState(
          status: PaymentGatewaysStatus.empty,
          gateways: [],
        ),
      ],
    );

    blocTest<PaymentGatewaysBloc, PaymentGatewaysState>(
      'emits [loading, failure] on WooCommerceException with error message and code',
      build: () {
        when(() => mockRepository.getPaymentGateways(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenThrow(const WooCommerceException(
          message: 'Consumer key is invalid.',
          statusCode: 401,
        ));
        return PaymentGatewaysBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const PaymentGatewaysFetchStarted()),
      expect: () => [
        const PaymentGatewaysState(
          status: PaymentGatewaysStatus.loading,
        ),
        const PaymentGatewaysState(
          status: PaymentGatewaysStatus.failure,
          errorMessage: 'Consumer key is invalid.',
          errorStatusCode: 401,
        ),
      ],
    );

    blocTest<PaymentGatewaysBloc, PaymentGatewaysState>(
      'deduplicates payment gateways with duplicate IDs',
      build: () {
        final duplicates = [
          GetPaymentGatewaysModel(id: 'bacs', title: 'First BACS', enabled: true),
          GetPaymentGatewaysModel(id: 'bacs', title: 'Second BACS', enabled: true),
          GetPaymentGatewaysModel(id: 'cod', title: 'COD', enabled: false),
        ];

        when(() => mockRepository.getPaymentGateways(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => duplicates);
        return PaymentGatewaysBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const PaymentGatewaysFetchStarted()),
      expect: () => [
        const PaymentGatewaysState(
          status: PaymentGatewaysStatus.loading,
        ),
        PaymentGatewaysState(
          status: PaymentGatewaysStatus.success,
          gateways: [
            GetPaymentGatewaysModel(id: 'bacs', title: 'First BACS', enabled: true),
            GetPaymentGatewaysModel(id: 'cod', title: 'COD', enabled: false),
          ],
        ),
      ],
    );

    blocTest<PaymentGatewaysBloc, PaymentGatewaysState>(
      'updates searchQuery on PaymentGatewaysSearchChanged',
      build: () => PaymentGatewaysBloc(repository: mockRepository),
      act: (bloc) => bloc.add(const PaymentGatewaysSearchChanged('bank')),
      expect: () => [
        const PaymentGatewaysState(searchQuery: 'bank'),
      ],
    );

    blocTest<PaymentGatewaysBloc, PaymentGatewaysState>(
      'updates selectedFilter on PaymentGatewaysFilterChanged',
      build: () => PaymentGatewaysBloc(repository: mockRepository),
      act: (bloc) => bloc.add(const PaymentGatewaysFilterChanged('enabled')),
      expect: () => [
        const PaymentGatewaysState(selectedFilter: 'enabled'),
      ],
    );
  });
}
