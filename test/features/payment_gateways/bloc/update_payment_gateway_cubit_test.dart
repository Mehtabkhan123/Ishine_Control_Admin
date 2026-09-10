import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/payment_gateways/bloc/update_payment_gateway_cubit.dart';
import 'package:ishine_admin_app/features/payment_gateways/bloc/update_payment_gateway_state.dart';
import 'package:ishine_admin_app/features/payment_gateways/data/models/put_update_payment_gateways_model.dart';
import 'package:ishine_admin_app/features/payment_gateways/data/repositories/payment_gateways_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockPaymentGatewaysRepository extends Mock
    implements PaymentGatewaysRepository {}

void main() {
  late MockPaymentGatewaysRepository mockRepository;

  final sampleUpdatedGateway = PutUpdatePaymentGatewaysModel(
    id: 'bacs',
    title: 'Direct Bank Transfer (Updated)',
    description: 'Updated wire instructions',
    order: 2,
    enabled: true,
  );

  setUp(() {
    mockRepository = MockPaymentGatewaysRepository();
  });

  group('UpdatePaymentGatewayCubit', () {
    test('initial state has correct defaults', () {
      final cubit = UpdatePaymentGatewayCubit(repository: mockRepository);
      expect(cubit.state.status, UpdatePaymentGatewayStatus.initial);
      expect(cubit.state.updatedGateway, isNull);
      expect(cubit.state.submittingGatewayId, isNull);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.isSuccess, isFalse);
      expect(cubit.state.isFailure, isFalse);
    });

    blocTest<UpdatePaymentGatewayCubit, UpdatePaymentGatewayState>(
      'emits [submitting, success] when updatePaymentGateway succeeds',
      build: () {
        when(() => mockRepository.updatePaymentGateway(
              id: any(named: 'id'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => sampleUpdatedGateway);
        return UpdatePaymentGatewayCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.updatePaymentGateway(
        gatewayId: 'bacs',
        updateData: {'title': 'Direct Bank Transfer (Updated)'},
      ),
      expect: () => [
        const UpdatePaymentGatewayState(
          status: UpdatePaymentGatewayStatus.submitting,
          submittingGatewayId: 'bacs',
        ),
        UpdatePaymentGatewayState(
          status: UpdatePaymentGatewayStatus.success,
          updatedGateway: sampleUpdatedGateway,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.updatePaymentGateway(
              id: 'bacs',
              data: {'title': 'Direct Bank Transfer (Updated)'},
            )).called(1);
      },
    );

    blocTest<UpdatePaymentGatewayCubit, UpdatePaymentGatewayState>(
      'emits [submitting, failure] when repository throws WooCommerceException',
      build: () {
        when(() => mockRepository.updatePaymentGateway(
              id: any(named: 'id'),
              data: any(named: 'data'),
            )).thenThrow(const WooCommerceException(
          message: 'Invalid gateway parameter',
          statusCode: 400,
        ));
        return UpdatePaymentGatewayCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.updatePaymentGateway(
        gatewayId: 'bacs',
        updateData: {'enabled': 'invalid'},
      ),
      expect: () => [
        const UpdatePaymentGatewayState(
          status: UpdatePaymentGatewayStatus.submitting,
          submittingGatewayId: 'bacs',
        ),
        const UpdatePaymentGatewayState(
          status: UpdatePaymentGatewayStatus.failure,
          errorMessage: 'Invalid gateway parameter',
          errorStatusCode: 400,
        ),
      ],
    );

    blocTest<UpdatePaymentGatewayCubit, UpdatePaymentGatewayState>(
      'emits [submitting, failure] on generic Exception',
      build: () {
        when(() => mockRepository.updatePaymentGateway(
              id: any(named: 'id'),
              data: any(named: 'data'),
            )).thenThrow(Exception('Connection timed out'));
        return UpdatePaymentGatewayCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.updatePaymentGateway(
        gatewayId: 'bacs',
        updateData: {'enabled': true},
      ),
      expect: () => [
        const UpdatePaymentGatewayState(
          status: UpdatePaymentGatewayStatus.submitting,
          submittingGatewayId: 'bacs',
        ),
        const UpdatePaymentGatewayState(
          status: UpdatePaymentGatewayStatus.failure,
          errorMessage: 'Connection timed out',
        ),
      ],
    );

    test('prevents duplicate concurrent submissions while in-flight', () async {
      when(() => mockRepository.updatePaymentGateway(
            id: any(named: 'id'),
            data: any(named: 'data'),
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 60));
        return sampleUpdatedGateway;
      });

      final cubit = UpdatePaymentGatewayCubit(repository: mockRepository);

      final f1 = cubit.updatePaymentGateway(
        gatewayId: 'bacs',
        updateData: {'title': 'Request 1'},
      );
      final f2 = cubit.updatePaymentGateway(
        gatewayId: 'bacs',
        updateData: {'title': 'Request 2'},
      );

      final r1 = await f1;
      final r2 = await f2;

      expect(r1, isNotNull);
      expect(r2, isNull); // second call is blocked

      verify(() => mockRepository.updatePaymentGateway(
            id: 'bacs',
            data: any(named: 'data'),
          )).called(1);
    });

    blocTest<UpdatePaymentGatewayCubit, UpdatePaymentGatewayState>(
      'toggleGatewayEnabled calls updatePaymentGateway with enabled map',
      build: () {
        when(() => mockRepository.updatePaymentGateway(
              id: any(named: 'id'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => sampleUpdatedGateway);
        return UpdatePaymentGatewayCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.toggleGatewayEnabled(
        gatewayId: 'bacs',
        enabled: true,
      ),
      expect: () => [
        const UpdatePaymentGatewayState(
          status: UpdatePaymentGatewayStatus.submitting,
          submittingGatewayId: 'bacs',
        ),
        UpdatePaymentGatewayState(
          status: UpdatePaymentGatewayStatus.success,
          updatedGateway: sampleUpdatedGateway,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.updatePaymentGateway(
              id: 'bacs',
              data: {'enabled': true},
            )).called(1);
      },
    );

    test('reset restores initial state', () {
      final cubit = UpdatePaymentGatewayCubit(repository: mockRepository);
      cubit.emit(UpdatePaymentGatewayState(
        status: UpdatePaymentGatewayStatus.success,
        updatedGateway: sampleUpdatedGateway,
      ));
      cubit.reset();
      expect(cubit.state.status, UpdatePaymentGatewayStatus.initial);
      expect(cubit.state.updatedGateway, isNull);
    });

    test('clearError removes error message', () {
      final cubit = UpdatePaymentGatewayCubit(repository: mockRepository);
      cubit.emit(const UpdatePaymentGatewayState(
        status: UpdatePaymentGatewayStatus.failure,
        errorMessage: 'Some error',
      ));
      cubit.clearError();
      expect(cubit.state.errorMessage, isNull);
    });
  });
}
