import 'package:equatable/equatable.dart';

abstract class SystemStatusEvent extends Equatable {
  const SystemStatusEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched when the app starts or when connection status needs to be checked.
class SystemStatusCheckRequested extends SystemStatusEvent {
  const SystemStatusCheckRequested();
}

/// Dispatched on user manual refresh.
class SystemStatusRefreshRequested extends SystemStatusEvent {
  const SystemStatusRefreshRequested();
}
