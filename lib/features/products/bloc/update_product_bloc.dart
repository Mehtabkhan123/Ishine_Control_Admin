import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/repositories/products_repository.dart';
import 'update_product_event.dart';
import 'update_product_state.dart';

/// BLoC managing product update lifecycle:
/// `PUT {{baseUrl}}/wp-json/wc/v3/products/{{productId}}`
/// Handles duplicate submission prevention, preloading product by ID, and taxonomy loading.
class UpdateProductBloc extends Bloc<UpdateProductEvent, UpdateProductState> {
  final ProductsRepository repository;

  // Duplicate submission tracking
  String? _lastSubmittedSignature;
  DateTime? _lastSubmittedAt;

  UpdateProductBloc({required this.repository})
      : super(const UpdateProductState()) {
    on<UpdateProductFetchRequested>(_onFetchRequested);
    on<UpdateProductTaxonomiesRequested>(_onTaxonomiesRequested);
    on<UpdateProductSubmitted>(_onSubmitted);
    on<UpdateProductReset>(_onReset);
  }

  Future<void> _onFetchRequested(
    UpdateProductFetchRequested event,
    Emitter<UpdateProductState> emit,
  ) async {
    emit(state.copyWith(status: UpdateProductStatus.loadingProduct));

    try {
      final product = await repository.getProductById(productId: event.productId);
      final categories = await repository.getCategories();
      final tags = await repository.getTags();

      emit(state.copyWith(
        status: UpdateProductStatus.initial,
        product: product,
        categories: categories,
        tags: tags,
        errorMessage: null,
      ));
    } on WooCommerceException catch (e) {
      final isTimeout = e.statusCode == 408 || e.message.toLowerCase().contains('timed out');
      final isNetwork = !isTimeout &&
          (e.message.toLowerCase().contains('connect') || e.message.toLowerCase().contains('network'));

      emit(state.copyWith(
        status: UpdateProductStatus.failure,
        errorMessage: e.message,
        statusCode: e.statusCode,
        isTimeout: isTimeout,
        isNetworkError: isNetwork,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UpdateProductStatus.failure,
        errorMessage: 'Failed to load product details: ${e.toString()}',
      ));
    }
  }

  Future<void> _onTaxonomiesRequested(
    UpdateProductTaxonomiesRequested event,
    Emitter<UpdateProductState> emit,
  ) async {
    emit(state.copyWith(status: UpdateProductStatus.loadingTaxonomies));

    try {
      final categories = await repository.getCategories();
      final tags = await repository.getTags();

      emit(state.copyWith(
        status: UpdateProductStatus.initial,
        categories: categories,
        tags: tags,
      ));
    } catch (_) {
      emit(state.copyWith(status: UpdateProductStatus.initial));
    }
  }

  Future<void> _onSubmitted(
    UpdateProductSubmitted event,
    Emitter<UpdateProductState> emit,
  ) async {
    // 1. Guard against in-flight duplicate submissions
    if (state.isSubmitting) {
      return;
    }

    final product = event.product;
    final productId = event.productId;
    final name = product.name?.trim() ?? '';
    final sku = product.sku?.trim() ?? '';
    final regularPrice = product.regularPrice?.trim() ?? '';
    final stockQty = product.stockQuantity?.toString() ?? '';

    // 2. Client-side validation
    if (productId <= 0) {
      emit(state.copyWith(
        status: UpdateProductStatus.failure,
        errorMessage: 'Invalid product ID for update.',
        statusCode: 400,
      ));
      return;
    }

    if (name.isEmpty) {
      emit(state.copyWith(
        status: UpdateProductStatus.failure,
        errorMessage: 'Product name cannot be empty.',
        statusCode: 400,
      ));
      return;
    }

    // 3. Prevent rapid duplicate submission of the identical update
    final currentSignature = '${productId}_${name.toLowerCase()}_${sku.toLowerCase()}_${regularPrice}_$stockQty';
    if (_lastSubmittedSignature == currentSignature &&
        _lastSubmittedAt != null &&
        DateTime.now().difference(_lastSubmittedAt!) < const Duration(seconds: 15)) {
      emit(state.copyWith(
        status: UpdateProductStatus.failure,
        errorMessage: 'Duplicate update prevented. This product update was just submitted.',
        isDuplicateBlocked: true,
      ));
      return;
    }

    // 4. Verify API credentials configured
    if (!EnvConfig.isConfigured) {
      emit(state.copyWith(
        status: UpdateProductStatus.failure,
        errorMessage: 'WooCommerce credentials are missing in .env configuration.',
      ));
      return;
    }

    emit(state.copyWith(
      status: UpdateProductStatus.submitting,
      clearError: true,
      isTimeout: false,
      isNetworkError: false,
      isDuplicateBlocked: false,
    ));

    try {
      final updatedProduct = await repository.updateProduct(
        productId: productId,
        product: product,
      );

      _lastSubmittedSignature = currentSignature;
      _lastSubmittedAt = DateTime.now();

      emit(state.copyWith(
        status: UpdateProductStatus.success,
        updatedProduct: updatedProduct,
        clearError: true,
      ));
    } on WooCommerceException catch (e) {
      final isTimeout = e.statusCode == 408 || e.message.toLowerCase().contains('timed out');
      final isNetwork = !isTimeout &&
          (e.message.toLowerCase().contains('connect') || e.message.toLowerCase().contains('network'));

      emit(state.copyWith(
        status: UpdateProductStatus.failure,
        errorMessage: e.message,
        statusCode: e.statusCode,
        isTimeout: isTimeout,
        isNetworkError: isNetwork,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UpdateProductStatus.failure,
        errorMessage: 'An unexpected error occurred while updating product: ${e.toString()}',
      ));
    }
  }

  void _onReset(
    UpdateProductReset event,
    Emitter<UpdateProductState> emit,
  ) {
    emit(state.copyWith(
      status: UpdateProductStatus.initial,
      clearError: true,
      isTimeout: false,
      isNetworkError: false,
      isDuplicateBlocked: false,
    ));
  }
}
