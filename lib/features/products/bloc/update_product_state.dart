import 'package:equatable/equatable.dart';
import '../data/models/post_create_model.dart';
import '../data/models/put_update_model.dart';

enum UpdateProductStatus {
  initial,
  loadingProduct,
  loadingTaxonomies,
  submitting,
  success,
  failure,
}

class UpdateProductState extends Equatable {
  final UpdateProductStatus status;
  final PutUpdateModel? product;
  final PutUpdateModel? updatedProduct;
  final List<ProductCategoryRef> categories;
  final List<ProductTagRef> tags;
  final String? errorMessage;
  final int? statusCode;
  final bool isTimeout;
  final bool isNetworkError;
  final bool isDuplicateBlocked;

  const UpdateProductState({
    this.status = UpdateProductStatus.initial,
    this.product,
    this.updatedProduct,
    this.categories = const [],
    this.tags = const [],
    this.errorMessage,
    this.statusCode,
    this.isTimeout = false,
    this.isNetworkError = false,
    this.isDuplicateBlocked = false,
  });

  bool get isSubmitting => status == UpdateProductStatus.submitting;
  bool get isSuccess => status == UpdateProductStatus.success;
  bool get isFailure => status == UpdateProductStatus.failure;
  bool get isLoadingProduct => status == UpdateProductStatus.loadingProduct;
  bool get isLoadingTaxonomies => status == UpdateProductStatus.loadingTaxonomies;

  UpdateProductState copyWith({
    UpdateProductStatus? status,
    PutUpdateModel? product,
    PutUpdateModel? updatedProduct,
    List<ProductCategoryRef>? categories,
    List<ProductTagRef>? tags,
    String? errorMessage,
    int? statusCode,
    bool? isTimeout,
    bool? isNetworkError,
    bool? isDuplicateBlocked,
    bool clearError = false,
  }) {
    return UpdateProductState(
      status: status ?? this.status,
      product: product ?? this.product,
      updatedProduct: updatedProduct ?? this.updatedProduct,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      statusCode: clearError ? null : (statusCode ?? this.statusCode),
      isTimeout: isTimeout ?? this.isTimeout,
      isNetworkError: isNetworkError ?? this.isNetworkError,
      isDuplicateBlocked: isDuplicateBlocked ?? this.isDuplicateBlocked,
    );
  }

  @override
  List<Object?> get props => [
        status,
        product,
        updatedProduct,
        categories,
        tags,
        errorMessage,
        statusCode,
        isTimeout,
        isNetworkError,
        isDuplicateBlocked,
      ];
}
