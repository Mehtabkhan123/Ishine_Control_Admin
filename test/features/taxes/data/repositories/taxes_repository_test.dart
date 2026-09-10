import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/taxes/data/models/get_tax_rates_model.dart';
import 'package:ishine_admin_app/features/taxes/data/models/post_tax_rates_model.dart';
import 'package:ishine_admin_app/features/taxes/data/repositories/taxes_repository.dart';
import 'package:ishine_admin_app/features/taxes/data/services/taxes_service.dart';
import 'package:mocktail/mocktail.dart';

class MockTaxesService extends Mock implements TaxesService {}

void main() {
  late MockTaxesService mockService;
  late TaxesRepository repository;

  final sampleResponse = TaxRatesResponse(
    taxRates: [
      GetTaxRatesModel(id: 1, name: 'Standard Tax', rate: '20.0000'),
      GetTaxRatesModel(id: 2, name: 'Reduced Tax', rate: '5.0000'),
    ],
    totalTaxRates: 2,
    totalPages: 1,
  );

  setUp(() {
    mockService = MockTaxesService();
    repository = TaxesRepository(service: mockService);
  });

  group('TaxesRepository', () {
    test('getTaxRates caches response and does not invoke service twice',
        () async {
      when(() => mockService.fetchTaxRates(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            taxClass: any(named: 'taxClass'),
            search: any(named: 'search'),
          )).thenAnswer((_) async => sampleResponse);

      final res1 = await repository.getTaxRates();
      expect(res1.taxRates.length, 2);

      final res2 = await repository.getTaxRates();
      expect(res2.taxRates.length, 2);

      verify(() => mockService.fetchTaxRates(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            taxClass: any(named: 'taxClass'),
            search: any(named: 'search'),
          )).called(1);
    });

    test('getTaxRates with forceRefresh queries service again', () async {
      when(() => mockService.fetchTaxRates(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            taxClass: any(named: 'taxClass'),
            search: any(named: 'search'),
          )).thenAnswer((_) async => sampleResponse);

      await repository.getTaxRates();
      await repository.getTaxRates(forceRefresh: true);

      verify(() => mockService.fetchTaxRates(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            taxClass: any(named: 'taxClass'),
            search: any(named: 'search'),
          )).called(2);
    });

    test('deduplicates concurrent in-flight requests', () async {
      when(() => mockService.fetchTaxRates(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            taxClass: any(named: 'taxClass'),
            search: any(named: 'search'),
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return sampleResponse;
      });

      final f1 = repository.getTaxRates();
      final f2 = repository.getTaxRates();
      final f3 = repository.getTaxRates();

      final results = await Future.wait([f1, f2, f3]);

      expect(results[0].taxRates.length, 2);
      expect(results[1].taxRates.length, 2);
      expect(results[2].taxRates.length, 2);

      verify(() => mockService.fetchTaxRates(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            taxClass: any(named: 'taxClass'),
            search: any(named: 'search'),
          )).called(1);
    });

    test('getTaxRate retrieves and caches single tax rate', () async {
      final sampleRate =
          GetTaxRatesModel(id: 1, name: 'Standard Tax', rate: '20.0000');

      when(() => mockService.fetchTaxRate(1))
          .thenAnswer((_) async => sampleRate);

      final r1 = await repository.getTaxRate(1);
      final r2 = await repository.getTaxRate(1);

      expect(r1.id, 1);
      expect(r2.id, 1);

      verify(() => mockService.fetchTaxRate(1)).called(1);
    });

    test('createTaxRate delegates to service and invalidates cached tax rates', () async {
      final inputModel = PostTaxRatesModel(
        name: 'New VAT',
        rate: '21.0000',
        country: 'NL',
      );
      final createdModel = PostTaxRatesModel(
        id: 77,
        name: 'New VAT',
        rate: '21.0000',
        country: 'NL',
      );

      when(() => mockService.fetchTaxRates(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            taxClass: any(named: 'taxClass'),
            search: any(named: 'search'),
          )).thenAnswer((_) async => sampleResponse);

      when(() => mockService.createTaxRate(inputModel))
          .thenAnswer((_) async => createdModel);

      // 1. Populate cache
      await repository.getTaxRates();

      // 2. Call createTaxRate
      final result = await repository.createTaxRate(inputModel);
      expect(result.id, 77);
      expect(result.name, 'New VAT');
      verify(() => mockService.createTaxRate(inputModel)).called(1);

      // 3. Subsequent getTaxRates() should query service again because cache was invalidated
      await repository.getTaxRates();
      verify(() => mockService.fetchTaxRates(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            taxClass: any(named: 'taxClass'),
            search: any(named: 'search'),
          )).called(2);
    });
  });
}
