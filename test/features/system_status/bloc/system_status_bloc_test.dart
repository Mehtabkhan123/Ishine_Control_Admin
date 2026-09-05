import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/system_status/bloc/system_status_bloc.dart';
import 'package:ishine_admin_app/features/system_status/bloc/system_status_event.dart';
import 'package:ishine_admin_app/features/system_status/bloc/system_status_state.dart';
import 'package:ishine_admin_app/features/system_status/data/models/system_status_model.dart';
import 'package:ishine_admin_app/features/system_status/data/repositories/system_status_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockSystemStatusRepository extends Mock implements SystemStatusRepository {}

void main() {
  late MockSystemStatusRepository mockRepository;
  late SystemStatus mockStatus;

  setUpAll(() {
    dotenv.testLoad(mergeWith: {
      'WOOCOMMERCE_BASE_URL': 'https://darkgrey-albatross-869937.hostingersite.com',
      'WOOCOMMERCE_CONSUMER_KEY': 'ck_test_key',
      'WOOCOMMERCE_CONSUMER_SECRET': 'cs_test_secret',
    });
  });

  setUp(() {
    mockRepository = MockSystemStatusRepository();
    mockStatus = SystemStatus(
      homeUrl: 'https://darkgrey-albatross-869937.hostingersite.com',
      siteUrl: 'https://darkgrey-albatross-869937.hostingersite.com',
      wcVersion: '9.4.0',
      wpVersion: '6.7.1',
      phpVersion: '8.2.20',
      serverInfo: 'LiteSpeed',
      mysqlVersion: '10.11.8',
      isSecure: true,
      isDebugMode: false,
      currency: 'USD',
      currencySymbol: '\$',
      activePluginsCount: 5,
      themeName: 'Astra',
      themeVersion: '4.8.0',
      responseTimeMs: 120,
      checkedAt: DateTime(2026, 1, 1),
    );
  });

  group('SystemStatusBloc', () {
    test('initial state is SystemStatusInitial with checking health', () {
      final bloc = SystemStatusBloc(repository: mockRepository);
      expect(bloc.state, const SystemStatusInitial());
      expect(bloc.state.health, ConnectionHealth.checking);
      bloc.close();
    });

    blocTest<SystemStatusBloc, SystemStatusState>(
      'emits [SystemStatusLoading, SystemStatusSuccess] when check succeeds',
      build: () {
        when(() => mockRepository.getSystemStatus()).thenAnswer((_) async => mockStatus);
        return SystemStatusBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const SystemStatusCheckRequested()),
      expect: () => [
        const SystemStatusLoading(),
        SystemStatusSuccess(status: mockStatus),
      ],
      verify: (_) {
        verify(() => mockRepository.getSystemStatus()).called(1);
      },
    );

    blocTest<SystemStatusBloc, SystemStatusState>(
      'emits [SystemStatusLoading, SystemStatusFailure] when API throws WooCommerceException',
      build: () {
        when(() => mockRepository.getSystemStatus()).thenThrow(
          const WooCommerceException(
            message: 'Authentication failed (401).',
            statusCode: 401,
          ),
        );
        return SystemStatusBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const SystemStatusCheckRequested()),
      expect: () => [
        const SystemStatusLoading(),
        const SystemStatusFailure(
          errorMessage: 'Authentication failed (401).',
          statusCode: 401,
        ),
      ],
    );
  });
}
