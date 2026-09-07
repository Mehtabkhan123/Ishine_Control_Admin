import 'package:equatable/equatable.dart';
import '../data/models/post_create_model.dart';

enum CreateProductStatus {
  initial,
  loadingTaxonomies,
  submitting,
  success,
  failure,
}

class CreateProductState extends Equatable {
  final CreateProductStatus status;
  final PostCreateModel? createdProduct;
  final List<ProductCategoryRef> categories;
  final List<ProductTagRef> tags;
  final String? errorMessage;
  final int? statusCode;
  final bool isTimeout;
  final bool isNetworkError;
  final bool isDuplicateBlocked;

  const CreateProductState({
    this.status = CreateProductStatus.initial,
    this.createdProduct,
    this.categories = const [],
    this.tags = const [],
    this.errorMessage,
    this.statusCode,
    this.isTimeout = false,
    this.isNetworkError = false,
    this.isDuplicateBlocked = false,
  });

  bool get isSubmitting => status == CreateProductStatus.submitting;
  bool get isSuccess => status == CreateProductStatus.success;
  bool get isFailure => status == CreateProductStatus.failure;
  bool get isLoadingTaxonomies => status == CreateProductStatus.loadingTaxonomies;

  CreateProductState copyWith({
    CreateProductStatus? status,
    PostCreateModel? createdProduct,
    List<ProductCategoryRef>? categories,
    List<ProductTagRef>? tags,
    String? errorMessage,
    int? statusCode,
    bool? isTimeout,
    bool? isNetworkError,
    bool? isDuplicateBlocked,
  }) {
    return CreateProductState(
      status: status ?? this.status,
      createdProduct: createdProduct ?? this.createdProduct,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      errorMessage: errorMessage ?? this.errorMessage,
      statusCode: statusCode ?? this.statusCode,
      isTimeout: isTimeout ?? this.isTimeout,
      isNetworkError: isNetworkError ?? this.isNetworkError,
      isDuplicateBlocked: isDuplicateBlocked ?? this.isDuplicateBlocked,
    );
  }

  @override
  List<Object?> get props => [
        status,
        createdProduct,
        categories,
        tags,
        errorMessage,
        statusCode,
        isTimeout,
        isNetworkError,
        isDuplicateBlocked,
      ];
}
