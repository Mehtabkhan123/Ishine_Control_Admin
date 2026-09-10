import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/taxes/bloc/create_tax_rate_cubit.dart';
import 'package:ishine_admin_app/features/taxes/bloc/create_tax_rate_state.dart';
import 'package:ishine_admin_app/features/taxes/data/models/post_tax_rates_model.dart';
import 'package:ishine_admin_app/features/taxes/data/repositories/taxes_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockTaxesRepository extends Mock implements TaxesRepository {}

class FakePostTaxRatesModel extends Fake implements PostTaxRatesModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakePostTaxRatesModel());
  });

  late MockTaxesRepository mockRepository;

  final sampleInput = PostTaxRatesModel(
    name: 'State Tax',
    rate: '7.2500',
    country: 'US',
    state: 'CA',
    postcode: '90001',
    city: 'Los Angeles',
    priority: 1,
    compound: false,
    shipping: true,
    order: 0,
    taxClass: 'standard',
  );

  final sampleCreated = PostTaxRatesModel(
    id: 55,
    name: 'State Tax',
    rate: '7.2500',
    country: 'US',
    state: 'CA',
    postcode: '90001',
    city: 'Los Angeles',
    priority: 1,
    compound: false,
    shipping: true,
    order: 0,
    taxClass: 'standard',
  );

  setUp(() {
    mockRepository = MockTaxesRepository();
  });

  group('CreateTaxRateCubit', () {
    test('initial state has correct default values', () {
      final cubit = CreateTaxRateCubit(repository: mockRepository);
      expect(cubit.state.status, CreateTaxRateStatus.initial);
      expect(cubit.state.createdTaxRate, isNull);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.isSuccess, isFalse);
      expect(cubit.state.isFailure, isFalse);
    });

    blocTest<CreateTaxRateCubit, CreateTaxRateState>(
      'emits [submitting, success] when createTaxRate succeeds',
      build: () {
        when(() => mockRepository.createTaxRate(any()))
            .thenAnswer((_) async => sampleCreated);
        return CreateTaxRateCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.createTaxRate(sampleInput),
      expect: () => [
        const CreateTaxRateState(status: CreateTaxRateStatus.submitting),
        CreateTaxRateState(
          status: CreateTaxRateStatus.success,
          createdTaxRate: sampleCreated,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.createTaxRate(sampleInput)).called(1);
      },
    );

    blocTest<CreateTaxRateCubit, CreateTaxRateState>(
      'emits [submitting, failure] with error message when repository throws WooCommerceException',
      build: () {
        when(() => mockRepository.createTaxRate(any()))
            .thenThrow(const WooCommerceException(
          message: 'Tax rate with this name already exists.',
          statusCode: 400,
        ));
        return CreateTaxRateCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.createTaxRate(sampleInput),
      expect: () => [
        const CreateTaxRateState(status: CreateTaxRateStatus.submitting),
        const CreateTaxRateState(
          status: CreateTaxRateStatus.failure,
          errorMessage: 'Tax rate with this name already exists.',
        ),
      ],
    );

    blocTest<CreateTaxRateCubit, CreateTaxRateState>(
      'emits [submitting, failure] when network error occurs',
      build: () {
        when(() => mockRepository.createTaxRate(any()))
            .thenThrow(const WooCommerceException(
          message: 'Connection failed',
        ));
        return CreateTaxRateCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.createTaxRate(sampleInput),
      expect: () => [
        const CreateTaxRateState(status: CreateTaxRateStatus.submitting),
        const CreateTaxRateState(
          status: CreateTaxRateStatus.failure,
          errorMessage: 'Connection failed',
        ),
      ],
    );

    test('ignores duplicate creation calls while isSubmitting is true', () async {
      when(() => mockRepository.createTaxRate(any()))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return sampleCreated;
      });

      final cubit = CreateTaxRateCubit(repository: mockRepository);

      final future1 = cubit.createTaxRate(sampleInput);
      final future2 = cubit.createTaxRate(sampleInput);

      final res1 = await future1;
      final res2 = await future2;

      expect(res1, sampleCreated);
      expect(res2, isNull);
      verify(() => mockRepository.createTaxRate(any())).called(1);
    });

    blocTest<CreateTaxRateCubit, CreateTaxRateState>(
      'reset() returns cubit to initial state',
      build: () => CreateTaxRateCubit(repository: mockRepository),
      seed: () => CreateTaxRateState(
        status: CreateTaxRateStatus.success,
        createdTaxRate: sampleCreated,
      ),
      act: (cubit) => cubit.reset(),
      expect: () => [
        const CreateTaxRateState(),
      ],
    );
  });
}
