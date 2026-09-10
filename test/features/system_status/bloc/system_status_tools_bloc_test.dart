import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/system_status/bloc/system_status_tools_bloc.dart';
import 'package:ishine_admin_app/features/system_status/bloc/system_status_tools_event.dart';
import 'package:ishine_admin_app/features/system_status/bloc/system_status_tools_state.dart';
import 'package:ishine_admin_app/features/system_status/data/models/get_system_status_tools_model.dart';
import 'package:ishine_admin_app/features/system_status/data/repositories/system_status_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockSystemStatusRepository extends Mock
    implements SystemStatusRepository {}

void main() {
  late MockSystemStatusRepository mockRepository;

  final sampleTools = [
    GetSystemStatusToolsModel(
      id: 'clear_transients',
      name: 'WooCommerce transients',
      action: 'Clear transients',
      description: 'This tool will clear the WooCommerce transients cache.',
    ),
    GetSystemStatusToolsModel(
      id: 'clear_expired_transients',
      name: 'Expired transients',
      action: 'Clear expired transients',
      description: 'This tool will clear expired WooCommerce transients.',
    ),
    GetSystemStatusToolsModel(
      id: 'recount_terms',
      name: 'Term counts',
      action: 'Recount terms',
      description: 'Recalculates product category and tag counts.',
    ),
  ];

  setUp(() {
    mockRepository = MockSystemStatusRepository();
  });

  group('SystemStatusToolsBloc', () {
    test('initial state has correct default values', () {
      final bloc = SystemStatusToolsBloc(repository: mockRepository);
      expect(bloc.state.status, SystemStatusToolsStatus.initial);
      expect(bloc.state.allTools, isEmpty);
      expect(bloc.state.filteredTools, isEmpty);
      expect(bloc.state.searchQuery, '');
      expect(bloc.state.executingToolId, isNull);
      expect(bloc.state.executionSuccessMessage, isNull);
      expect(bloc.state.executionErrorMessage, isNull);
    });

    blocTest<SystemStatusToolsBloc, SystemStatusToolsState>(
      'emits [loading, success] on successful SystemStatusToolsFetchStarted',
      build: () {
        when(() => mockRepository.getSystemStatusTools(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => sampleTools);
        return SystemStatusToolsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const SystemStatusToolsFetchStarted()),
      expect: () => [
        const SystemStatusToolsState(status: SystemStatusToolsStatus.loading),
        isA<SystemStatusToolsState>()
            .having((s) => s.status, 'status', SystemStatusToolsStatus.success)
            .having((s) => s.allTools.length, 'allTools.length', 3)
            .having((s) => s.filteredTools.length, 'filteredTools.length', 3),
      ],
    );

    blocTest<SystemStatusToolsBloc, SystemStatusToolsState>(
      'emits [loading, empty] when repository returns empty list',
      build: () {
        when(() => mockRepository.getSystemStatusTools(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => []);
        return SystemStatusToolsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const SystemStatusToolsFetchStarted()),
      expect: () => [
        const SystemStatusToolsState(status: SystemStatusToolsStatus.loading),
        isA<SystemStatusToolsState>()
            .having((s) => s.status, 'status', SystemStatusToolsStatus.empty)
            .having((s) => s.allTools, 'allTools', isEmpty),
      ],
    );

    blocTest<SystemStatusToolsBloc, SystemStatusToolsState>(
      'emits [loading, failure] on WooCommerceException',
      build: () {
        when(() => mockRepository.getSystemStatusTools(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenThrow(
          const WooCommerceException(
            message: 'Forbidden API access',
            statusCode: 403,
          ),
        );
        return SystemStatusToolsBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const SystemStatusToolsFetchStarted()),
      expect: () => [
        const SystemStatusToolsState(status: SystemStatusToolsStatus.loading),
        isA<SystemStatusToolsState>()
            .having((s) => s.status, 'status', SystemStatusToolsStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', 'Forbidden API access')
            .having((s) => s.errorCode, 'errorCode', 403),
      ],
    );

    blocTest<SystemStatusToolsBloc, SystemStatusToolsState>(
      'filters tools correctly when SystemStatusToolsSearchChanged is dispatched',
      build: () => SystemStatusToolsBloc(repository: mockRepository),
      seed: () => SystemStatusToolsState(
        status: SystemStatusToolsStatus.success,
        allTools: sampleTools,
        filteredTools: sampleTools,
      ),
      act: (bloc) => bloc.add(const SystemStatusToolsSearchChanged('recount')),
      expect: () => [
        isA<SystemStatusToolsState>()
            .having((s) => s.searchQuery, 'searchQuery', 'recount')
            .having((s) => s.filteredTools.length, 'filteredTools.length', 1)
            .having((s) => s.filteredTools.first.id, 'filteredTools.first.id',
                'recount_terms'),
      ],
    );

    blocTest<SystemStatusToolsBloc, SystemStatusToolsState>(
      'executes tool and emits success message on SystemStatusToolExecuteRequested',
      build: () {
        when(() => mockRepository.executeSystemStatusTool(
              id: 'clear_transients',
            )).thenAnswer(
          (_) async => GetSystemStatusToolsModel(
            id: 'clear_transients',
            name: 'WooCommerce transients',
            action: 'Clear transients',
            description: 'Transients cleared successfully.',
          ),
        );
        return SystemStatusToolsBloc(repository: mockRepository);
      },
      seed: () => SystemStatusToolsState(
        status: SystemStatusToolsStatus.success,
        allTools: sampleTools,
        filteredTools: sampleTools,
      ),
      act: (bloc) => bloc.add(
        const SystemStatusToolExecuteRequested(toolId: 'clear_transients'),
      ),
      expect: () => [
        isA<SystemStatusToolsState>()
            .having((s) => s.executingToolId, 'executingToolId', 'clear_transients'),
        isA<SystemStatusToolsState>()
            .having((s) => s.executingToolId, 'executingToolId', isNull)
            .having((s) => s.executionSuccessMessage, 'executionSuccessMessage',
                contains('completed')),
      ],
    );

    blocTest<SystemStatusToolsBloc, SystemStatusToolsState>(
      'handles execution error cleanly',
      build: () {
        when(() => mockRepository.executeSystemStatusTool(
              id: 'clear_transients',
            )).thenThrow(
          const WooCommerceException(
            message: 'Action failed on server',
            statusCode: 500,
          ),
        );
        return SystemStatusToolsBloc(repository: mockRepository);
      },
      seed: () => SystemStatusToolsState(
        status: SystemStatusToolsStatus.success,
        allTools: sampleTools,
        filteredTools: sampleTools,
      ),
      act: (bloc) => bloc.add(
        const SystemStatusToolExecuteRequested(toolId: 'clear_transients'),
      ),
      expect: () => [
        isA<SystemStatusToolsState>()
            .having((s) => s.executingToolId, 'executingToolId', 'clear_transients'),
        isA<SystemStatusToolsState>()
            .having((s) => s.executingToolId, 'executingToolId', isNull)
            .having((s) => s.executionErrorMessage, 'executionErrorMessage',
                'Action failed on server'),
      ],
    );

    blocTest<SystemStatusToolsBloc, SystemStatusToolsState>(
      'clears execution feedback when SystemStatusToolsExecutionFeedbackCleared dispatched',
      build: () => SystemStatusToolsBloc(repository: mockRepository),
      seed: () => const SystemStatusToolsState(
        executionSuccessMessage: 'Done',
        executionErrorMessage: 'Error',
      ),
      act: (bloc) =>
          bloc.add(const SystemStatusToolsExecutionFeedbackCleared()),
      expect: () => [
        isA<SystemStatusToolsState>()
            .having((s) => s.executionSuccessMessage, 'successMessage', isNull)
            .having((s) => s.executionErrorMessage, 'errorMessage', isNull),
      ],
    );
  });
}
