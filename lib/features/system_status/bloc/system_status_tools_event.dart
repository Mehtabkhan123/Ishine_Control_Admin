import 'package:equatable/equatable.dart';

/// Base class for all System Status Tools events.
abstract class SystemStatusToolsEvent extends Equatable {
  const SystemStatusToolsEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched to trigger the initial or background fetch of system status tools.
class SystemStatusToolsFetchStarted extends SystemStatusToolsEvent {
  final bool forceRefresh;

  const SystemStatusToolsFetchStarted({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

/// Dispatched when the user pulls down to refresh or taps the reload button.
class SystemStatusToolsRefreshRequested extends SystemStatusToolsEvent {
  const SystemStatusToolsRefreshRequested();
}

/// Dispatched when the user enters or changes search terms in the tools filter bar.
class SystemStatusToolsSearchChanged extends SystemStatusToolsEvent {
  final String query;

  const SystemStatusToolsSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Dispatched after user confirms intent to execute a specific system status tool action.
class SystemStatusToolExecuteRequested extends SystemStatusToolsEvent {
  final String toolId;

  const SystemStatusToolExecuteRequested({required this.toolId});

  @override
  List<Object?> get props => [toolId];
}

/// Dispatched to clear execution success/error snackbar feedback after it has been shown.
class SystemStatusToolsExecutionFeedbackCleared extends SystemStatusToolsEvent {
  const SystemStatusToolsExecutionFeedbackCleared();
}
