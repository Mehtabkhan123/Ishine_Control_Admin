import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ishine_admin_app/core/config/env_config.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/system_status/data/repositories/system_status_repository.dart';
import 'system_status_event.dart';
import 'system_status_state.dart';

class SystemStatusBloc extends Bloc<SystemStatusEvent, SystemStatusState> {
  final SystemStatusRepository repository;

  SystemStatusBloc({required this.repository})
      : super(const SystemStatusInitial()) {
    on<SystemStatusCheckRequested>(_onCheckRequested);
    on<SystemStatusRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onCheckRequested(
    SystemStatusCheckRequested event,
    Emitter<SystemStatusState> emit,
  ) async {
    await _fetchStatus(emit);
  }

  Future<void> _onRefreshRequested(
    SystemStatusRefreshRequested event,
    Emitter<SystemStatusState> emit,
  ) async {
    await _fetchStatus(emit);
  }

  Future<void> _fetchStatus(Emitter<SystemStatusState> emit) async {
    if (!EnvConfig.isConfigured) {
      emit(
        const SystemStatusFailure(
          errorMessage: 'WooCommerce credentials are missing in .env file.',
        ),
      );
      return;
    }

    emit(SystemStatusLoading(status: state.status));

    try {
      final status = await repository.getSystemStatus();
      emit(SystemStatusSuccess(status: status));
    } on WooCommerceException catch (e) {
      emit(
        SystemStatusFailure(
          errorMessage: e.message,
          statusCode: e.statusCode,
          status: state.status,
        ),
      );
    } catch (e) {
      emit(
        SystemStatusFailure(
          errorMessage: 'Failed to connect: ${e.toString()}',
          status: state.status,
        ),
      );
    }
  }
}
