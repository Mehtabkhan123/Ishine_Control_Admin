import 'package:equatable/equatable.dart';
import '../data/models/sales_report_model.dart';

abstract class SalesReportState extends Equatable {
  final String period;
  final GetSalesReportModel? report;

  const SalesReportState({
    this.period = 'month',
    this.report,
  });

  @override
  List<Object?> get props => [period, report];
}

class SalesReportInitial extends SalesReportState {
  const SalesReportInitial() : super(period: 'month');
}

class SalesReportLoading extends SalesReportState {
  const SalesReportLoading({
    super.period = 'month',
    super.report,
  });
}

class SalesReportSuccess extends SalesReportState {
  final DateTime lastUpdated;

  const SalesReportSuccess({
    required super.report,
    required super.period,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [period, report, lastUpdated];
}

class SalesReportEmpty extends SalesReportState {
  const SalesReportEmpty({
    required super.period,
  });

  @override
  List<Object?> get props => [period];
}

class SalesReportFailure extends SalesReportState {
  final String errorMessage;
  final int? statusCode;
  final bool isTimeout;
  final bool isNetworkError;

  const SalesReportFailure({
    required this.errorMessage,
    this.statusCode,
    required super.period,
    this.isTimeout = false,
    this.isNetworkError = false,
    super.report,
  });

  @override
  List<Object?> get props => [
        period,
        report,
        errorMessage,
        statusCode,
        isTimeout,
        isNetworkError,
      ];
}
