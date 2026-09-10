import 'package:equatable/equatable.dart';
import '../data/models/get_system_status_tools_model.dart';

enum SystemStatusToolsStatus {
  initial,
  loading,
  success,
  empty,
  failure,
}

class SystemStatusToolsState extends Equatable {
  final SystemStatusToolsStatus status;
  final List<GetSystemStatusToolsModel> allTools;
  final List<GetSystemStatusToolsModel> filteredTools;
  final String searchQuery;
  final String? executingToolId;
  final String? executionSuccessMessage;
  final String? executionErrorMessage;
  final String? errorMessage;
  final int? errorCode;
  final DateTime? lastUpdated;

  const SystemStatusToolsState({
    this.status = SystemStatusToolsStatus.initial,
    this.allTools = const [],
    this.filteredTools = const [],
    this.searchQuery = '',
    this.executingToolId,
    this.executionSuccessMessage,
    this.executionErrorMessage,
    this.errorMessage,
    this.errorCode,
    this.lastUpdated,
  });

  bool get isInitial => status == SystemStatusToolsStatus.initial;
  bool get isLoading => status == SystemStatusToolsStatus.loading;
  bool get isSuccess => status == SystemStatusToolsStatus.success;
  bool get isEmpty => status == SystemStatusToolsStatus.empty;
  bool get isFailure => status == SystemStatusToolsStatus.failure;

  int get totalCount => allTools.length;
  int get filteredCount => filteredTools.length;

  bool isExecuting(String? id) => id != null && executingToolId == id;
  bool get isAnyExecuting => executingToolId != null;

  int get toolsWithActionsCount => allTools.where((t) => t.hasAction).length;

  SystemStatusToolsState copyWith({
    SystemStatusToolsStatus? status,
    List<GetSystemStatusToolsModel>? allTools,
    List<GetSystemStatusToolsModel>? filteredTools,
    String? searchQuery,
    String? executingToolId,
    bool clearExecutingToolId = false,
    String? executionSuccessMessage,
    bool clearExecutionSuccessMessage = false,
    String? executionErrorMessage,
    bool clearExecutionErrorMessage = false,
    String? errorMessage,
    int? errorCode,
    DateTime? lastUpdated,
  }) {
    return SystemStatusToolsState(
      status: status ?? this.status,
      allTools: allTools ?? this.allTools,
      filteredTools: filteredTools ?? this.filteredTools,
      searchQuery: searchQuery ?? this.searchQuery,
      executingToolId: clearExecutingToolId
          ? null
          : (executingToolId ?? this.executingToolId),
      executionSuccessMessage: clearExecutionSuccessMessage
          ? null
          : (executionSuccessMessage ?? this.executionSuccessMessage),
      executionErrorMessage: clearExecutionErrorMessage
          ? null
          : (executionErrorMessage ?? this.executionErrorMessage),
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: errorCode ?? this.errorCode,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        status,
        allTools,
        filteredTools,
        searchQuery,
        executingToolId,
        executionSuccessMessage,
        executionErrorMessage,
        errorMessage,
        errorCode,
        lastUpdated,
      ];
}
