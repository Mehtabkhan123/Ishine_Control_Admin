import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/models/post_create_model.dart';
import '../data/repositories/products_repository.dart';
import 'create_category_state.dart';

/// Cubit managing category creation lifecycle, duplicate submission prevention,
/// parent categories fetching, image upload, and error classification.
class CreateCategoryCubit extends Cubit<CreateCategoryState> {
  final ProductsRepository repository;

  // Duplicate submission tracking
  String? _lastSubmittedSignature;
  DateTime? _lastSubmittedAt;

  CreateCategoryCubit({required this.repository})
      : super(const CreateCategoryState());

  /// Loads available categories to populate the parent category dropdown.
  Future<void> loadParentCategories() async {
    emit(state.copyWith(
      status: CreateCategoryStatus.loadingParents,
      clearError: true,
    ));

    try {
      final categories = await repository.getCategories();
      emit(state.copyWith(
        status: CreateCategoryStatus.initial,
        parentCategories: categories,
      ));
    } catch (e) {
      debugPrint('⚠️ [CreateCategoryCubit] Failed to load parent categories: $e');
      emit(state.copyWith(status: CreateCategoryStatus.initial));
    }
  }

  /// Sets an image by URL or existing reference.
  void setImage(ProductImageRef? image) {
    emit(state.copyWith(
      selectedImage: image,
      clearImage: image == null,
      clearError: true,
    ));
  }

  /// Uploads an image from bytes (picked from gallery/camera) to WordPress/WooCommerce media.
  Future<void> uploadImage({
    required Uint8List bytes,
    required String filename,
  }) async {
    if (state.isUploadingImage || state.isSubmitting) return;

    emit(state.copyWith(
      status: CreateCategoryStatus.uploadingImage,
      uploadProgress: 0.0,
      clearError: true,
    ));

    try {
      final uploadedRef = await repository.uploadMedia(
        bytes: bytes,
        filename: filename,
        onProgress: (progress) {
          emit(state.copyWith(uploadProgress: progress));
        },
      );

      emit(state.copyWith(
        status: CreateCategoryStatus.initial,
        selectedImage: uploadedRef,
        uploadProgress: 1.0,
      ));
    } catch (e) {
      String msg = 'Failed to upload category image: ${e.toString()}';
      if (e is WooCommerceException) {
        msg = e.message;
      }
      emit(state.copyWith(
        status: CreateCategoryStatus.failure,
        errorMessage: msg,
      ));
    }
  }

  /// Removes the currently selected category image.
  void removeImage() {
    emit(state.copyWith(clearImage: true));
  }

  /// Submits the new category to WooCommerce REST API: `POST /wp-json/wc/v3/products/categories`.
  Future<ProductCategoryRef?> submitCategory({
    required String name,
    String? slug,
    String? description,
    int? parentId,
    String? display,
    ProductImageRef? image,
  }) async {
    // 1. Guard against duplicate submission while in flight
    if (state.isSubmitting || state.isUploadingImage) {
      return null;
    }

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      emit(state.copyWith(
        status: CreateCategoryStatus.failure,
        errorMessage: 'Category name is required.',
      ));
      return null;
    }

    // 2. Duplicate submission cooldown protection (same name/slug submitted within 2.5 seconds)
    final signature = '${trimmedName.toLowerCase()}_${(slug ?? '').trim().toLowerCase()}_$parentId';
    final now = DateTime.now();
    if (_lastSubmittedSignature == signature &&
        _lastSubmittedAt != null &&
        now.difference(_lastSubmittedAt!) < const Duration(milliseconds: 2500)) {
      emit(state.copyWith(
        status: CreateCategoryStatus.failure,
        errorMessage: 'Category submission is already in progress. Please wait a moment.',
      ));
      return null;
    }
    _lastSubmittedSignature = signature;
    _lastSubmittedAt = now;

    emit(state.copyWith(
      status: CreateCategoryStatus.submitting,
      clearError: true,
    ));

    final effectiveImage = image ?? state.selectedImage;

    final categoryToCreate = ProductCategoryRef(
      name: trimmedName,
      slug: (slug != null && slug.trim().isNotEmpty) ? slug.trim() : null,
      description: (description != null && description.trim().isNotEmpty) ? description.trim() : null,
      parent: (parentId != null && parentId > 0) ? parentId : 0,
      display: (display != null && display.isNotEmpty) ? display : 'default',
      image: effectiveImage,
    );

    try {
      final created = await repository.createCategory(categoryToCreate);

      emit(state.copyWith(
        status: CreateCategoryStatus.success,
        createdCategory: created,
        clearError: true,
      ));

      return created;
    } on WooCommerceException catch (e) {
      String message = e.message;
      if (e.errorData is Map && e.errorData['code'] == 'term_exists') {
        message = 'A category with this name or slug already exists in WooCommerce.';
      } else if (e.statusCode == 401 || e.statusCode == 403) {
        message = 'Permission denied (HTTP ${e.statusCode}). Ensure your WooCommerce API key has Read/Write permissions.';
      } else if (e.statusCode == 400) {
        message = 'WooCommerce rejected category data: ${e.message}';
      }

      emit(state.copyWith(
        status: CreateCategoryStatus.failure,
        errorMessage: message,
        errorCode: e.statusCode,
      ));
      return null;
    } catch (e) {
      emit(state.copyWith(
        status: CreateCategoryStatus.failure,
        errorMessage: 'Unexpected error creating category: ${e.toString()}',
      ));
      return null;
    }
  }

  /// Updates an existing category via WooCommerce REST API:
  /// `PUT /wp-json/wc/v3/products/categories/{{categoryId}}`.
  Future<ProductCategoryRef?> updateCategory({
    required int categoryId,
    required String name,
    String? slug,
    String? description,
    int? parentId,
    String? display,
    ProductImageRef? image,
  }) async {
    // 1. Guard against duplicate submission while in flight
    if (state.isSubmitting || state.isUploadingImage || state.isDeleting) {
      return null;
    }

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      emit(state.copyWith(
        status: CreateCategoryStatus.failure,
        errorMessage: 'Category name is required.',
      ));
      return null;
    }

    if (parentId != null && parentId == categoryId) {
      emit(state.copyWith(
        status: CreateCategoryStatus.failure,
        errorMessage: 'A category cannot be its own parent.',
      ));
      return null;
    }

    // 2. Duplicate submission cooldown protection
    final signature =
        'upd_${categoryId}_${trimmedName.toLowerCase()}_${(slug ?? '').trim().toLowerCase()}_$parentId';
    final now = DateTime.now();
    if (_lastSubmittedSignature == signature &&
        _lastSubmittedAt != null &&
        now.difference(_lastSubmittedAt!) <
            const Duration(milliseconds: 2500)) {
      emit(state.copyWith(
        status: CreateCategoryStatus.failure,
        errorMessage:
            'Category update is already in progress. Please wait a moment.',
      ));
      return null;
    }
    _lastSubmittedSignature = signature;
    _lastSubmittedAt = now;

    emit(state.copyWith(
      status: CreateCategoryStatus.submitting,
      clearError: true,
    ));

    final effectiveImage = image ?? state.selectedImage;

    final categoryToUpdate = ProductCategoryRef(
      id: categoryId,
      name: trimmedName,
      slug: (slug != null && slug.trim().isNotEmpty) ? slug.trim() : null,
      description: (description != null && description.trim().isNotEmpty)
          ? description.trim()
          : null,
      parent: (parentId != null && parentId > 0) ? parentId : 0,
      display: (display != null && display.isNotEmpty) ? display : 'default',
      image: effectiveImage,
    );

    try {
      final updated = await repository.updateCategory(
        categoryId: categoryId,
        category: categoryToUpdate,
      );

      emit(state.copyWith(
        status: CreateCategoryStatus.success,
        updatedCategory: updated,
        createdCategory: updated,
        clearError: true,
      ));

      return updated;
    } on WooCommerceException catch (e) {
      String message = e.message;
      if (e.errorData is Map && e.errorData['code'] == 'term_exists') {
        message =
            'A category with this name or slug already exists in WooCommerce.';
      } else if (e.statusCode == 401 || e.statusCode == 403) {
        message =
            'Permission denied (HTTP ${e.statusCode}). Ensure your WooCommerce API key has Read/Write permissions.';
      } else if (e.statusCode == 404) {
        message = 'Category #$categoryId was not found in WooCommerce.';
      } else if (e.statusCode == 400) {
        message = 'WooCommerce rejected category update: ${e.message}';
      }

      emit(state.copyWith(
        status: CreateCategoryStatus.failure,
        errorMessage: message,
        errorCode: e.statusCode,
      ));
      return null;
    } catch (e) {
      emit(state.copyWith(
        status: CreateCategoryStatus.failure,
        errorMessage: 'Unexpected error updating category: ${e.toString()}',
      ));
      return null;
    }
  }

  /// Deletes a category via WooCommerce REST API:
  /// `DELETE /wp-json/wc/v3/products/categories/{{categoryId}}?force=true`.
  Future<bool> deleteCategory(
    int categoryId, {
    bool force = true,
  }) async {
    if (state.isSubmitting || state.isUploadingImage || state.isDeleting) {
      return false;
    }

    emit(state.copyWith(
      status: CreateCategoryStatus.deleting,
      clearError: true,
    ));

    try {
      final success = await repository.deleteCategory(
        categoryId: categoryId,
        force: force,
      );

      if (success) {
        emit(state.copyWith(
          status: CreateCategoryStatus.deleteSuccess,
          deletedCategoryId: categoryId,
          clearError: true,
        ));
        return true;
      } else {
        emit(state.copyWith(
          status: CreateCategoryStatus.failure,
          errorMessage: 'Failed to delete category #$categoryId.',
        ));
        return false;
      }
    } on WooCommerceException catch (e) {
      String message = e.message;
      if (e.statusCode == 401 || e.statusCode == 403) {
        message =
            'Permission denied (HTTP ${e.statusCode}). Ensure your WooCommerce API key has Read/Write permissions.';
      } else if (e.statusCode == 404) {
        message = 'Category #$categoryId does not exist in WooCommerce.';
      }

      emit(state.copyWith(
        status: CreateCategoryStatus.failure,
        errorMessage: message,
        errorCode: e.statusCode,
      ));
      return false;
    } catch (e) {
      emit(state.copyWith(
        status: CreateCategoryStatus.failure,
        errorMessage: 'Unexpected error deleting category: ${e.toString()}',
      ));
      return false;
    }
  }

  /// Resets state back to initial.
  void reset() {
    emit(const CreateCategoryState());
  }
}

/// Type alias for backward compatibility and semantic flexibility
typedef CategoryCrudCubit = CreateCategoryCubit;

