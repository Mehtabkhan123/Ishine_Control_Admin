import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/shipping/data/models/shipping_zones_model.dart';
import 'package:ishine_admin_app/features/shipping/data/repositories/shipping_repository.dart';
import 'package:ishine_admin_app/features/shipping/data/services/shipping_service.dart';
import 'package:mocktail/mocktail.dart';

class MockShippingService extends Mock implements ShippingService {}

void main() {
  late MockShippingService mockService;
  late ShippingRepository repository;

  final sampleResponse = ShippingZonesResponse(
    zones: [
      ShippingZonesModel(id: 1, name: 'North America', order: 0),
      ShippingZonesModel(id: 2, name: 'Europe', order: 1),
    ],
    totalZones: 2,
    totalPages: 1,
  );

  setUp(() {
    mockService = MockShippingService();
    repository = ShippingRepository(service: mockService);
  });

  group('ShippingRepository', () {
    test('getShippingZones caches response and does not call service twice',
        () async {
      when(() => mockService.fetchShippingZones(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            search: any(named: 'search'),
          )).thenAnswer((_) async => sampleResponse);

      // Call 1
      final res1 = await repository.getShippingZones();
      expect(res1.zones.length, 2);

      // Call 2 (should return cached)
      final res2 = await repository.getShippingZones();
      expect(res2.zones.length, 2);

      verify(() => mockService.fetchShippingZones(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            search: any(named: 'search'),
          )).called(1);
    });

    test('getShippingZones with forceRefresh calls service again', () async {
      when(() => mockService.fetchShippingZones(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            search: any(named: 'search'),
          )).thenAnswer((_) async => sampleResponse);

      await repository.getShippingZones();
      await repository.getShippingZones(forceRefresh: true);

      verify(() => mockService.fetchShippingZones(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            search: any(named: 'search'),
          )).called(2);
    });

    test('deduplicates concurrent in-flight requests', () async {
      when(() => mockService.fetchShippingZones(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            search: any(named: 'search'),
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return sampleResponse;
      });

      // Fire 3 concurrent requests simultaneously
      final future1 = repository.getShippingZones();
      final future2 = repository.getShippingZones();
      final future3 = repository.getShippingZones();

      final results = await Future.wait([future1, future2, future3]);

      expect(results[0].zones.length, 2);
      expect(results[1].zones.length, 2);
      expect(results[2].zones.length, 2);

      // Service should have only been invoked once!
      verify(() => mockService.fetchShippingZones(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            search: any(named: 'search'),
          )).called(1);
    });

    test('getShippingZone retrieves and caches single zone', () async {
      final sampleZone = ShippingZonesModel(id: 1, name: 'US Zone', order: 0);

      when(() => mockService.fetchShippingZone(1))
          .thenAnswer((_) async => sampleZone);

      final zone1 = await repository.getShippingZone(1);
      final zone2 = await repository.getShippingZone(1);

      expect(zone1.id, 1);
      expect(zone2.id, 1);

      verify(() => mockService.fetchShippingZone(1)).called(1);
    });
  });
}
