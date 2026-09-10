import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/models/get_system_status_tools_model.dart';
import '../data/repositories/system_status_repository.dart';
import 'system_status_tools_event.dart';
import 'system_status_tools_state.dart';

class SystemStatusToolsBloc
    extends Bloc<SystemStatusToolsEvent, SystemStatusToolsState> {
  final SystemStatusRepository repository;

  SystemStatusToolsBloc({required this.repository})
      : super(const SystemStatusToolsState()) {
    on<SystemStatusToolsFetchStarted>(_onFetchStarted);
    on<SystemStatusToolsRefreshRequested>(_onRefreshRequested);
    on<SystemStatusToolsSearchChanged>(_onSearchChanged);
    on<SystemStatusToolExecuteRequested>(_onToolExecuteRequested);
    on<SystemStatusToolsExecutionFeedbackCleared>(_onExecutionFeedbackCleared);
  }

  Future<void> _onFetchStarted(
    SystemStatusToolsFetchStarted event,
    Emitter<SystemStatusToolsState> emit,
  ) async {
    emit(state.copyWith(
      status: SystemStatusToolsStatus.loading,
      errorMessage: null,
      errorCode: null,
    ));

    try {
      final tools = await repository.getSystemStatusTools(
        forceRefresh: event.forceRefresh,
      );

      // Deduplicate by ID
      final seenIds = <String>{};
      final uniqueTools = <GetSystemStatusToolsModel>[];
      for (final t in tools) {
        final id = t.id ?? '';
        if (id.isEmpty || seenIds.add(id)) {
          uniqueTools.add(t);
        }
      }

      if (uniqueTools.isEmpty) {
        emit(state.copyWith(
          status: SystemStatusToolsStatus.empty,
          allTools: [],
          filteredTools: [],
          lastUpdated: DateTime.now(),
        ));
      } else {
        final filtered = _applyFilters(uniqueTools, state.searchQuery);
        emit(state.copyWith(
          status: SystemStatusToolsStatus.success,
          allTools: uniqueTools,
          filteredTools: filtered,
          lastUpdated: DateTime.now(),
        ));
      }
    } on WooCommerceException catch (e) {
      emit(state.copyWith(
        status: SystemStatusToolsStatus.failure,
        errorMessage: e.message,
        errorCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SystemStatusToolsStatus.failure,
        errorMessage:
            'An unexpected error occurred while loading system status tools: $e',
      ));
    }
  }

  Future<void> _onRefreshRequested(
    SystemStatusToolsRefreshRequested event,
    Emitter<SystemStatusToolsState> emit,
  ) async {
    add(const SystemStatusToolsFetchStarted(forceRefresh: true));
  }

  void _onSearchChanged(
    SystemStatusToolsSearchChanged event,
    Emitter<SystemStatusToolsState> emit,
  ) {
    final filtered = _applyFilters(state.allTools, event.query);
    emit(state.copyWith(
      searchQuery: event.query,
      filteredTools: filtered,
    ));
  }

  Future<void> _onToolExecuteRequested(
    SystemStatusToolExecuteRequested event,
    Emitter<SystemStatusToolsState> emit,
  ) async {
    // Avoid re-triggering if already executing a tool
    if (state.isAnyExecuting) return;

    emit(state.copyWith(
      executingToolId: event.toolId,
      clearExecutionSuccessMessage: true,
      clearExecutionErrorMessage: true,
    ));

    try {
      final updatedTool =
          await repository.executeSystemStatusTool(id: event.toolId);

      // Update tools list with returned model
      final updatedAllTools = state.allTools.map((tool) {
        return tool.id == event.toolId ? updatedTool : tool;
      }).toList();

      final filtered = _applyFilters(updatedAllTools, state.searchQuery);

      emit(state.copyWith(
        allTools: updatedAllTools,
        filteredTools: filtered,
        clearExecutingToolId: true,
        executionSuccessMessage:
            'Action "${updatedTool.displayAction}" completed for ${updatedTool.displayName}',
      ));
    } on WooCommerceException catch (e) {
      emit(state.copyWith(
        clearExecutingToolId: true,
        executionErrorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        clearExecutingToolId: true,
        executionErrorMessage: 'Failed to execute tool: $e',
      ));
    }
  }

  void _onExecutionFeedbackCleared(
    SystemStatusToolsExecutionFeedbackCleared event,
    Emitter<SystemStatusToolsState> emit,
  ) {
    emit(state.copyWith(
      clearExecutionSuccessMessage: true,
      clearExecutionErrorMessage: true,
    ));
  }

  List<GetSystemStatusToolsModel> _applyFilters(
    List<GetSystemStatusToolsModel> tools,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return tools;

    return tools.where((tool) {
      final id = tool.id?.toLowerCase() ?? '';
      final name = tool.name?.toLowerCase() ?? '';
      final action = tool.action?.toLowerCase() ?? '';
      final desc = tool.description?.toLowerCase() ?? '';

      return id.contains(q) ||
          name.contains(q) ||
          action.contains(q) ||
          desc.contains(q);
    }).toList();
  }
}
