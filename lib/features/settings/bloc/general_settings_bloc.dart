import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/models/get_general_settings_model.dart';
import '../data/repositories/general_settings_repository.dart';
import 'general_settings_event.dart';
import 'general_settings_state.dart';

class GeneralSettingsBloc
    extends Bloc<GeneralSettingsEvent, GeneralSettingsState> {
  final GeneralSettingsRepository repository;

  GeneralSettingsBloc({required this.repository})
      : super(const GeneralSettingsState()) {
    on<GeneralSettingsFetchStarted>(_onFetchStarted);
    on<GeneralSettingsRefreshRequested>(_onRefreshRequested);
    on<GeneralSettingsSearchChanged>(_onSearchChanged);
    on<GeneralSettingsTypeFilterChanged>(_onTypeFilterChanged);
  }

  Future<void> _onFetchStarted(
    GeneralSettingsFetchStarted event,
    Emitter<GeneralSettingsState> emit,
  ) async {
    emit(state.copyWith(
      status: GeneralSettingsStatus.loading,
      errorMessage: null,
      errorCode: null,
    ));

    try {
      final settings = await repository.getGeneralSettings(
        forceRefresh: event.forceRefresh,
      );

      // Deduplicate by ID
      final seenIds = <String>{};
      final uniqueSettings = <GetGeneralSettingsModel>[];
      for (final s in settings) {
        final id = s.id ?? '';
        if (id.isEmpty || seenIds.add(id)) {
          uniqueSettings.add(s);
        }
      }

      if (uniqueSettings.isEmpty) {
        emit(state.copyWith(
          status: GeneralSettingsStatus.empty,
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
          status: GeneralSettingsStatus.success,
          allSettings: uniqueSettings,
          filteredSettings: filtered,
          lastUpdated: DateTime.now(),
        ));
      }
    } on WooCommerceException catch (e) {
      emit(state.copyWith(
        status: GeneralSettingsStatus.failure,
        errorMessage: e.message,
        errorCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: GeneralSettingsStatus.failure,
        errorMessage: 'An unexpected error occurred while loading settings: $e',
      ));
    }
  }

  Future<void> _onRefreshRequested(
    GeneralSettingsRefreshRequested event,
    Emitter<GeneralSettingsState> emit,
  ) async {
    add(const GeneralSettingsFetchStarted(forceRefresh: true));
  }

  void _onSearchChanged(
    GeneralSettingsSearchChanged event,
    Emitter<GeneralSettingsState> emit,
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
    GeneralSettingsTypeFilterChanged event,
    Emitter<GeneralSettingsState> emit,
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

  List<GetGeneralSettingsModel> _applyFilters(
    List<GetGeneralSettingsModel> settings,
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
