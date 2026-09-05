import 'package:equatable/equatable.dart';
import 'package:ishine_admin_app/features/system_status/data/models/system_status_model.dart';

enum ConnectionHealth { checking, healthy, degraded, failed }

abstract class SystemStatusState extends Equatable {
  final ConnectionHealth health;
  final SystemStatus? status;

  const SystemStatusState({
    this.health = ConnectionHealth.checking,
    this.status,
  });

  @override
  List<Object?> get props => [health, status];
}

class SystemStatusInitial extends SystemStatusState {
  const SystemStatusInitial() : super(health: ConnectionHealth.checking);
}

class SystemStatusLoading extends SystemStatusState {
  const SystemStatusLoading({super.status})
      : super(health: ConnectionHealth.checking);
}

class SystemStatusSuccess extends SystemStatusState {
  const SystemStatusSuccess({required SystemStatus status})
      : super(
          health: ConnectionHealth.healthy,
          status: status,
        );
}

class SystemStatusFailure extends SystemStatusState {
  final String errorMessage;
  final int? statusCode;

  const SystemStatusFailure({
    required this.errorMessage,
    this.statusCode,
    super.status,
  }) : super(health: ConnectionHealth.failed);

  @override
  List<Object?> get props => [health, status, errorMessage, statusCode];
}
