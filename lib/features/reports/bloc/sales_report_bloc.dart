import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/repositories/reports_repository.dart';
import 'sales_report_event.dart';
import 'sales_report_state.dart';

class SalesReportBloc extends Bloc<SalesReportEvent, SalesReportState> {
  final ReportsRepository repository;

  SalesReportBloc({required this.repository}) : super(const SalesReportInitial()) {
    on<SalesReportFetchRequested>(_onFetchRequested);
    on<SalesReportRefreshRequested>(_onRefreshRequested);
    on<SalesReportPeriodChanged>(_onPeriodChanged);
  }

  Future<void> _onFetchRequested(
    SalesReportFetchRequested event,
    Emitter<SalesReportState> emit,
  ) async {
    // Prevent duplicate calls during rebuilds if currently loading or already loaded for the same period
    if (!event.forceRefresh &&
        state.period == event.period &&
        (state is SalesReportLoading || state is SalesReportSuccess)) {
      return;
    }

    await _loadReport(
      emit,
      period: event.period,
      dateMin: event.dateMin,
      dateMax: event.dateMax,
      forceRefresh: event.forceRefresh,
    );
  }


  Future<void> _onRefreshRequested(
    SalesReportRefreshRequested event,
    Emitter<SalesReportState> emit,
  ) async {
    await _loadReport(
      emit,
      period: state.period,
      forceRefresh: true,
    );
  }

  Future<void> _onPeriodChanged(
    SalesReportPeriodChanged event,
    Emitter<SalesReportState> emit,
  ) async {
    if (state.period == event.period && state is SalesReportSuccess) {
      return;
    }
    await _loadReport(
      emit,
      period: event.period,
      forceRefresh: false,
    );
  }

  Future<void> _loadReport(
    Emitter<SalesReportState> emit, {
    required String period,
    String? dateMin,
    String? dateMax,
    bool forceRefresh = false,
  }) async {
    if (!EnvConfig.isConfigured) {
      emit(
        SalesReportFailure(
          errorMessage: 'WooCommerce credentials are missing in .env configuration.',
          period: period,
          report: state.report,
        ),
      );
      return;
    }

    emit(SalesReportLoading(
      period: period,
      report: state.report,
    ));

    try {
      final report = await repository.getSalesReport(
        period: period,
        dateMin: dateMin,
        dateMax: dateMax,
        forceRefresh: forceRefresh,
      );

      if (report == null || report.isEmptyReport) {
        emit(SalesReportEmpty(period: period));
      } else {
        emit(
          SalesReportSuccess(
            report: report,
            period: period,
            lastUpdated: DateTime.now(),
          ),
        );
      }
    } on WooCommerceException catch (e) {
      final isTimeout = e.statusCode == 408 || e.message.toLowerCase().contains('timed out');
      final isNetwork = !isTimeout &&
          (e.message.toLowerCase().contains('connect') || e.message.toLowerCase().contains('network'));


      emit(
        SalesReportFailure(
          errorMessage: e.message,
          statusCode: e.statusCode,
          period: period,
          isTimeout: isTimeout,
          isNetworkError: isNetwork,
          report: state.report,
        ),
      );
    } catch (e) {
      emit(
        SalesReportFailure(
          errorMessage: 'An unexpected error occurred: ${e.toString()}',
          period: period,
          report: state.report,
        ),
      );
    }
  }
}
