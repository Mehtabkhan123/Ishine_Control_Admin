import 'package:flutter/foundation.dart';
import '../../data/models/system_status_model.dart';
import '../../data/repositories/system_status_repository.dart';
import '../../data/services/system_status_service.dart';

/// Example StateNotifier / ChangeNotifier Controller demonstrating how to consume
/// [SystemStatusRepository] and [SystemStatusService] in a Flutter UI or state-management layer.
class SystemStatusController extends ChangeNotifier {
  final SystemStatusRepository _repository;

  SystemStatusController({SystemStatusRepository? repository})
      : _repository = repository ?? SystemStatusRepository();

  bool _isLoading = false;
  String? _errorMessage;
  GETSystemStatusModel? _systemStatusModel;
  SystemStatus? _domainStatus;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  GETSystemStatusModel? get systemStatusModel => _systemStatusModel;
  SystemStatus? get domainStatus => _domainStatus;

  /// Loads system status using default environment credentials or custom overrides.
  Future<void> loadSystemStatus({
    String? customBaseUrl,
    String? customConsumerKey,
    String? customConsumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch raw full model
      _systemStatusModel = await _repository.fetchSystemStatus(
        baseUrl: customBaseUrl,
        consumerKey: customConsumerKey,
        consumerSecret: customConsumerSecret,
        authMode: authMode,
      );

      // 2. Map to domain status for UI rendering
      _domainStatus = _systemStatusModel?.toDomain();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}

/// Standalone helper demonstrating a quick one-off async invocation.
///
/// Usage:
/// ```dart
/// final status = await fetchSystemStatusQuickExample();
/// print('Connected to: ${status.environment?.siteUrl}');
/// ```
Future<GETSystemStatusModel> fetchSystemStatusQuickExample({
  String? baseUrl,
  String? consumerKey,
  String? consumerSecret,
  WooCommerceAuthMode authMode = WooCommerceAuthMode.header,
}) async {
  final service = SystemStatusService();
  return await service.fetchSystemStatus(
    baseUrl: baseUrl,
    consumerKey: consumerKey,
    consumerSecret: consumerSecret,
    authMode: authMode,
  );
}
