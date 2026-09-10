import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/models/get_tax_settings_model.dart';
import '../data/repositories/tax_settings_repository.dart';
import 'tax_settings_event.dart';
import 'tax_settings_state.dart';

class TaxSettingsBloc extends Bloc<TaxSettingsEvent, TaxSettingsState> {
  final TaxSettingsRepository repository;

  TaxSettingsBloc({required this.repository})
      : super(const TaxSettingsState()) {
    on<TaxSettingsFetchStarted>(_onFetchStarted);
    on<TaxSettingsRefreshRequested>(_onRefreshRequested);
    on<TaxSettingsSearchChanged>(_onSearchChanged);
    on<TaxSettingsTypeFilterChanged>(_onTypeFilterChanged);
  }

  Future<void> _onFetchStarted(
    TaxSettingsFetchStarted event,
    Emitter<TaxSettingsState> emit,
  ) async {
    emit(state.copyWith(
      status: TaxSettingsStatus.loading,
      errorMessage: null,
      errorCode: null,
    ));

    try {
      final settings = await repository.getTaxSettings(
        forceRefresh: event.forceRefresh,
      );

      // Deduplicate by ID
      final seenIds = <String>{};
      final uniqueSettings = <GetTextSettingsModel>[];
      for (final s in settings) {
        final id = s.id ?? '';
        if (id.isEmpty || seenIds.add(id)) {
          uniqueSettings.add(s);
        }
      }

      if (uniqueSettings.isEmpty) {
        emit(state.copyWith(
          status: TaxSettingsStatus.empty,
          allSettings: [],
          filteredSettings: [],
          lastUpdated: DateTime.now(),
        ));
      } else {
        final filtered = _applyFilters(
          uniqueSettings,
          state.searchQuery,
          state.selectedTypeFilter,
        );
        emit(state.copyWith(
          status: TaxSettingsStatus.success,
          allSettings: uniqueSettings,
          filteredSettings: filtered,
          lastUpdated: DateTime.now(),
        ));
      }
    } on WooCommerceException catch (e) {
      emit(state.copyWith(
        status: TaxSettingsStatus.failure,
        errorMessage: e.message,
        errorCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TaxSettingsStatus.failure,
        errorMessage:
            'An unexpected error occurred while loading tax settings: $e',
      ));
    }
  }

  Future<void> _onRefreshRequested(
    TaxSettingsRefreshRequested event,
    Emitter<TaxSettingsState> emit,
  ) async {
    add(const TaxSettingsFetchStarted(forceRefresh: true));
  }

  void _onSearchChanged(
    TaxSettingsSearchChanged event,
    Emitter<TaxSettingsState> emit,
  ) {
    final filtered = _applyFilters(
      state.allSettings,
      event.query,
      state.selectedTypeFilter,
    );
    emit(state.copyWith(
      searchQuery: event.query,
      filteredSettings: filtered,
    ));
  }

  void _onTypeFilterChanged(
    TaxSettingsTypeFilterChanged event,
    Emitter<TaxSettingsState> emit,
  ) {
    final filtered = _applyFilters(
      state.allSettings,
      state.searchQuery,
      event.typeFilter,
    );
    emit(state.copyWith(
      selectedTypeFilter: event.typeFilter,
      clearTypeFilter: event.typeFilter == null,
      filteredSettings: filtered,
    ));
  }

  List<GetTextSettingsModel> _applyFilters(
    List<GetTextSettingsModel> settings,
    String query,
    String? typeFilter,
  ) {
    final q = query.trim().toLowerCase();
    final tf = typeFilter?.trim().toLowerCase();

    return settings.where((setting) {
      // 1. Filter by setting type if specified
      if (tf != null && tf.isNotEmpty) {
        final sType = setting.type?.trim().toLowerCase() ?? '';
        if (sType != tf) {
          return false;
        }
      }

      // 2. Filter by search query if present
      if (q.isEmpty) {
        return true;
      }

      final id = setting.id?.toLowerCase() ?? '';
      final label = setting.label?.toLowerCase() ?? '';
      final desc = setting.description?.toLowerCase() ?? '';
      final tip = setting.tip?.toLowerCase() ?? '';
      final val = setting.stringValue.toLowerCase();
      final defVal = setting.stringDefaultValue.toLowerCase();

      return id.contains(q) ||
          label.contains(q) ||
          desc.contains(q) ||
          tip.contains(q) ||
          val.contains(q) ||
          defVal.contains(q);
    }).toList();
  }
}
