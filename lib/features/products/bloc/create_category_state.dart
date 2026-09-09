import 'package:equatable/equatable.dart';
import '../data/models/post_create_model.dart';

/// Lifecycle statuses for category CRUD operations in WooCommerce.
enum CreateCategoryStatus {
  initial,
  loadingParents,
  uploadingImage,
  submitting,
  deleting,
  success,
  deleteSuccess,
  failure,
}

/// Immutable state for category operations.
class CreateCategoryState extends Equatable {
  final CreateCategoryStatus status;
  final List<ProductCategoryRef> parentCategories;
  final ProductCategoryRef? createdCategory;
  final ProductCategoryRef? updatedCategory;
  final int? deletedCategoryId;
  final String? errorMessage;
  final int? errorCode;
  final ProductImageRef? selectedImage;
  final double uploadProgress;

  const CreateCategoryState({
    this.status = CreateCategoryStatus.initial,
    this.parentCategories = const [],
    this.createdCategory,
    this.updatedCategory,
    this.deletedCategoryId,
    this.errorMessage,
    this.errorCode,
    this.selectedImage,
    this.uploadProgress = 0.0,
  });

  bool get isLoadingParents => status == CreateCategoryStatus.loadingParents;
  bool get isUploadingImage => status == CreateCategoryStatus.uploadingImage;
  bool get isSubmitting => status == CreateCategoryStatus.submitting;
  bool get isDeleting => status == CreateCategoryStatus.deleting;
  bool get isSuccess => status == CreateCategoryStatus.success;
  bool get isDeleteSuccess => status == CreateCategoryStatus.deleteSuccess;
  bool get isFailure => status == CreateCategoryStatus.failure;
  bool get isBusy =>
      isSubmitting || isUploadingImage || isLoadingParents || isDeleting;

  CreateCategoryState copyWith({
    CreateCategoryStatus? status,
    List<ProductCategoryRef>? parentCategories,
    ProductCategoryRef? createdCategory,
    ProductCategoryRef? updatedCategory,
    int? deletedCategoryId,
    String? errorMessage,
    bool clearError = false,
    int? errorCode,
    ProductImageRef? selectedImage,
    bool clearImage = false,
    double? uploadProgress,
  }) {
    return CreateCategoryState(
      status: status ?? this.status,
      parentCategories: parentCategories ?? this.parentCategories,
      createdCategory: createdCategory ?? this.createdCategory,
      updatedCategory: updatedCategory ?? this.updatedCategory,
      deletedCategoryId: deletedCategoryId ?? this.deletedCategoryId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      selectedImage: clearImage ? null : (selectedImage ?? this.selectedImage),
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }

  @override
  List<Object?> get props => [
        status,
        parentCategories,
        createdCategory,
        updatedCategory,
        deletedCategoryId,
        errorMessage,
        errorCode,
        selectedImage,
        uploadProgress,
      ];
}

/// Type alias for semantic flexibility
typedef CategoryCrudState = CreateCategoryState;

