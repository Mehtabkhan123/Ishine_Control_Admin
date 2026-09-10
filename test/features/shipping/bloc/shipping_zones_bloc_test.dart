import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/shipping/bloc/shipping_zones_bloc.dart';
import 'package:ishine_admin_app/features/shipping/bloc/shipping_zones_event.dart';
import 'package:ishine_admin_app/features/shipping/bloc/shipping_zones_state.dart';
import 'package:ishine_admin_app/features/shipping/data/models/shipping_zones_model.dart';
import 'package:ishine_admin_app/features/shipping/data/repositories/shipping_repository.dart';
import 'package:ishine_admin_app/features/shipping/data/services/shipping_service.dart';
import 'package:mocktail/mocktail.dart';

class MockShippingRepository extends Mock implements ShippingRepository {}

void main() {
  late MockShippingRepository mockRepository;

  final sampleZones = [
    ShippingZonesModel(id: 1, name: 'North America', order: 0),
    ShippingZonesModel(id: 2, name: 'European Union', order: 1),
  ];

  setUp(() {
    mockRepository = MockShippingRepository();
  });

  group('ShippingZonesBloc', () {
    test('initial state has correct default values', () {
      final bloc = ShippingZonesBloc(repository: mockRepository);
      expect(bloc.state.status, ShippingZonesStatus.initial);
      expect(bloc.state.zones, isEmpty);
      expect(bloc.state.currentPage, 1);
      expect(bloc.state.hasReachedMax, false);
      expect(bloc.state.isLoadingMore, false);
      expect(bloc.state.searchQuery, '');
    });

    blocTest<ShippingZonesBloc, ShippingZonesState>(
      'emits [loading, success] on successful ShippingZonesFetchStarted',
      build: () {
        when(() => mockRepository.getShippingZones(
              page: 1,
              perPage: 50,
              search: null,
              forceRefresh: false,
            )).thenAnswer((_) async => ShippingZonesResponse(
              zones: sampleZones,
              totalZones: 2,
              totalPages: 1,
            ));
        return ShippingZonesBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const ShippingZonesFetchStarted()),
      expect: () => [
        const ShippingZonesState(
          status: ShippingZonesStatus.loading,
          currentPage: 1,
          hasReachedMax: false,
        ),
        ShippingZonesState(
          status: ShippingZonesStatus.success,
          zones: sampleZones,
          currentPage: 1,
          hasReachedMax: true,
          totalZones: 2,
          totalPages: 1,
        ),
      ],
    );

    blocTest<ShippingZonesBloc, ShippingZonesState>(
      'emits [loading, empty] when store returns empty shipping zones list',
      build: () {
        when(() => mockRepository.getShippingZones(
              page: 1,
              perPage: 50,
              search: null,
              forceRefresh: false,
            )).thenAnswer((_) async => const ShippingZonesResponse(
              zones: [],
              totalZones: 0,
              totalPages: 1,
            ));
        return ShippingZonesBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const ShippingZonesFetchStarted()),
      expect: () => [
        const ShippingZonesState(
          status: ShippingZonesStatus.loading,
          currentPage: 1,
          hasReachedMax: false,
        ),
        const ShippingZonesState(
          status: ShippingZonesStatus.empty,
          zones: [],
          currentPage: 1,
          hasReachedMax: true,
          totalZones: 0,
          totalPages: 1,
        ),
      ],
    );

    blocTest<ShippingZonesBloc, ShippingZonesState>(
      'emits [loading, failure] with status code on WooCommerceException',
      build: () {
        when(() => mockRepository.getShippingZones(
              page: 1,
              perPage: 50,
              search: null,
              forceRefresh: false,
            )).thenThrow(const WooCommerceException(
          message: 'Authentication failed (401). Verify consumer credentials.',
          statusCode: 401,
        ));
        return ShippingZonesBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const ShippingZonesFetchStarted()),
      expect: () => [
        const ShippingZonesState(
          status: ShippingZonesStatus.loading,
          currentPage: 1,
          hasReachedMax: false,
        ),
        const ShippingZonesState(
          status: ShippingZonesStatus.failure,
          errorMessage:
              'Authentication failed (401). Verify consumer credentials.',
          errorStatusCode: 401,
        ),
      ],
    );

    blocTest<ShippingZonesBloc, ShippingZonesState>(
      'deduplicates duplicate zones with same ID in response',
      build: () {
        final duplicatedZones = [
          ShippingZonesModel(id: 1, name: 'North America', order: 0),
          ShippingZonesModel(id: 1, name: 'North America (Duplicate)', order: 0),
          ShippingZonesModel(id: 2, name: 'European Union', order: 1),
        ];

        when(() => mockRepository.getShippingZones(
              page: 1,
              perPage: 50,
              search: null,
              forceRefresh: false,
            )).thenAnswer((_) async => ShippingZonesResponse(
              zones: duplicatedZones,
              totalZones: 2,
              totalPages: 1,
            ));
        return ShippingZonesBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const ShippingZonesFetchStarted()),
      expect: () => [
        const ShippingZonesState(
          status: ShippingZonesStatus.loading,
          currentPage: 1,
          hasReachedMax: false,
        ),
        ShippingZonesState(
          status: ShippingZonesStatus.success,
          zones: sampleZones, // duplicates stripped!
          currentPage: 1,
          hasReachedMax: true,
          totalZones: 2,
          totalPages: 1,
        ),
      ],
    );

    blocTest<ShippingZonesBloc, ShippingZonesState>(
      'loads more zones and appends without duplicates on ShippingZonesLoadMore',
      build: () {
        final page2Zones = [
          ShippingZonesModel(id: 2, name: 'European Union (Duplicate)', order: 1),
          ShippingZonesModel(id: 3, name: 'Asia Pacific', order: 2),
        ];

        when(() => mockRepository.getShippingZones(
              page: 2,
              perPage: 50,
              search: null,
            )).thenAnswer((_) async => ShippingZonesResponse(
              zones: page2Zones,
              totalZones: 3,
              totalPages: 2,
            ));
        return ShippingZonesBloc(repository: mockRepository);
      },
      seed: () => ShippingZonesState(
        status: ShippingZonesStatus.success,
        zones: sampleZones,
        currentPage: 1,
        hasReachedMax: false,
        totalZones: 3,
        totalPages: 2,
      ),
      act: (bloc) => bloc.add(const ShippingZonesLoadMore()),
      expect: () => [
        ShippingZonesState(
          status: ShippingZonesStatus.success,
          zones: sampleZones,
          currentPage: 1,
          hasReachedMax: false,
          isLoadingMore: true,
          totalZones: 3,
          totalPages: 2,
        ),
        ShippingZonesState(
          status: ShippingZonesStatus.success,
          zones: [
            ...sampleZones,
            ShippingZonesModel(id: 3, name: 'Asia Pacific', order: 2),
          ],
          currentPage: 2,
          hasReachedMax: true,
          isLoadingMore: false,
          totalZones: 3,
          totalPages: 2,
        ),
      ],
    );
  });
}
