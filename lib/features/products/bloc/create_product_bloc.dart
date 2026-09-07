import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/repositories/products_repository.dart';
import 'create_product_event.dart';
import 'create_product_state.dart';

/// BLoC managing product creation lifecycle, duplicate submission prevention,
/// taxonomy fetching, and error categorization.
class CreateProductBloc extends Bloc<CreateProductEvent, CreateProductState> {
  final ProductsRepository repository;

  // Duplicate submission tracking
  String? _lastSubmittedSignature;
  DateTime? _lastSubmittedAt;

  CreateProductBloc({required this.repository})
      : super(const CreateProductState()) {
    on<CreateProductTaxonomiesRequested>(_onTaxonomiesRequested);
    on<CreateProductSubmitted>(_onSubmitted);
    on<CreateProductReset>(_onReset);
  }

  Future<void> _onTaxonomiesRequested(
    CreateProductTaxonomiesRequested event,
    Emitter<CreateProductState> emit,
  ) async {
    emit(state.copyWith(status: CreateProductStatus.loadingTaxonomies));

    try {
      final categoriesFuture = repository.getCategories();
      final tagsFuture = repository.getTags();

      final results = await Future.wait([categoriesFuture, tagsFuture]);
      final categories = results[0].cast<dynamic>();
      final tags = results[1].cast<dynamic>();

      emit(state.copyWith(
        status: CreateProductStatus.initial,
        categories: categories.cast(),
        tags: tags.cast(),
      ));
    } catch (_) {
      // Non-blocking for taxonomy failures; form can still submit without loaded categories
      emit(state.copyWith(status: CreateProductStatus.initial));
    }
  }

  Future<void> _onSubmitted(
    CreateProductSubmitted event,
    Emitter<CreateProductState> emit,
  ) async {
    // 1. Guard against in-flight duplicate submissions
    if (state.isSubmitting) {
      return;
    }

    final product = event.product;
    final name = product.name?.trim() ?? '';
    final sku = product.sku?.trim() ?? '';

    // 2. Client-side validation
    if (name.isEmpty) {
      emit(state.copyWith(
        status: CreateProductStatus.failure,
        errorMessage: 'Product name is required.',
        statusCode: 400,
        isTimeout: false,
        isNetworkError: false,
      ));
      return;
    }

    // 3. Prevent accidental duplicate rapid submission
    final currentSignature = '${name.toLowerCase()}_${sku.toLowerCase()}';
    if (_lastSubmittedSignature == currentSignature &&
        _lastSubmittedAt != null &&
        DateTime.now().difference(_lastSubmittedAt!) < const Duration(seconds: 15)) {
      emit(state.copyWith(
        status: CreateProductStatus.failure,
        errorMessage: 'Duplicate submission prevented. This product was just created or submitted.',
        isDuplicateBlocked: true,
      ));
      return;
    }

    // 4. Verify API credentials configured
    if (!EnvConfig.isConfigured) {
      emit(state.copyWith(
        status: CreateProductStatus.failure,
        errorMessage: 'WooCommerce credentials are missing in .env configuration.',
      ));
      return;
    }

    emit(state.copyWith(
      status: CreateProductStatus.submitting,
      errorMessage: null,
      isTimeout: false,
      isNetworkError: false,
      isDuplicateBlocked: false,
    ));

    try {
      final createdProduct = await repository.createProduct(product);

      _lastSubmittedSignature = currentSignature;
      _lastSubmittedAt = DateTime.now();

      emit(state.copyWith(
        status: CreateProductStatus.success,
        createdProduct: createdProduct,
        errorMessage: null,
      ));
    } on WooCommerceException catch (e) {
      final isTimeout = e.statusCode == 408 || e.message.toLowerCase().contains('timed out');
      final isNetwork = !isTimeout &&
          (e.message.toLowerCase().contains('connect') || e.message.toLowerCase().contains('network'));

      emit(state.copyWith(
        status: CreateProductStatus.failure,
        errorMessage: e.message,
        statusCode: e.statusCode,
        isTimeout: isTimeout,
        isNetworkError: isNetwork,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CreateProductStatus.failure,
        errorMessage: 'An unexpected error occurred: ${e.toString()}',
      ));
    }
  }

  void _onReset(
    CreateProductReset event,
    Emitter<CreateProductState> emit,
  ) {
    emit(state.copyWith(
      status: CreateProductStatus.initial,
      errorMessage: null,
      statusCode: null,
      isTimeout: false,
      isNetworkError: false,
      isDuplicateBlocked: false,
    ));
  }
}
