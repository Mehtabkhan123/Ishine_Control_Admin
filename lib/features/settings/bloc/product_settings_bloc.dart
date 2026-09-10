import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/models/get_product_settings_model.dart';
import '../data/repositories/product_settings_repository.dart';
import 'product_settings_event.dart';
import 'product_settings_state.dart';

class ProductSettingsBloc
    extends Bloc<ProductSettingsEvent, ProductSettingsState> {
  final ProductSettingsRepository repository;

  ProductSettingsBloc({required this.repository})
      : super(const ProductSettingsState()) {
    on<ProductSettingsFetchStarted>(_onFetchStarted);
    on<ProductSettingsRefreshRequested>(_onRefreshRequested);
    on<ProductSettingsSearchChanged>(_onSearchChanged);
    on<ProductSettingsTypeFilterChanged>(_onTypeFilterChanged);
  }

  Future<void> _onFetchStarted(
    ProductSettingsFetchStarted event,
    Emitter<ProductSettingsState> emit,
  ) async {
    emit(state.copyWith(
      status: ProductSettingsStatus.loading,
      errorMessage: null,
      errorCode: null,
    ));

    try {
      final settings = await repository.getProductSettings(
        forceRefresh: event.forceRefresh,
      );

      // Deduplicate by ID
      final seenIds = <String>{};
      final uniqueSettings = <GetProductSettingsModel>[];
      for (final s in settings) {
        final id = s.id ?? '';
        if (id.isEmpty || seenIds.add(id)) {
          uniqueSettings.add(s);
        }
      }

      if (uniqueSettings.isEmpty) {
        emit(state.copyWith(
          status: ProductSettingsStatus.empty,
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
          status: ProductSettingsStatus.success,
          allSettings: uniqueSettings,
          filteredSettings: filtered,
          lastUpdated: DateTime.now(),
        ));
      }
    } on WooCommerceException catch (e) {
      emit(state.copyWith(
        status: ProductSettingsStatus.failure,
        errorMessage: e.message,
        errorCode: e.statusCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProductSettingsStatus.failure,
        errorMessage:
            'An unexpected error occurred while loading product settings: $e',
      ));
    }
  }

  Future<void> _onRefreshRequested(
    ProductSettingsRefreshRequested event,
    Emitter<ProductSettingsState> emit,
  ) async {
    add(const ProductSettingsFetchStarted(forceRefresh: true));
  }

  void _onSearchChanged(
    ProductSettingsSearchChanged event,
    Emitter<ProductSettingsState> emit,
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
    ProductSettingsTypeFilterChanged event,
    Emitter<ProductSettingsState> emit,
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

  List<GetProductSettingsModel> _applyFilters(
    List<GetProductSettingsModel> settings,
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
