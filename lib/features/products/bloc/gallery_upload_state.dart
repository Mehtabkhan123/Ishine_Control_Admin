import 'package:equatable/equatable.dart';
import '../data/models/gallery_image_item.dart';
import '../data/models/post_create_model.dart';

/// State of the product gallery image selection and upload cubit.
class GalleryUploadState extends Equatable {
  final List<GalleryImageItem> items;
  final bool isUploading;
  final bool isPicking;
  final double overallProgress;
  final String? errorMessage;
  final String? successMessage;

  const GalleryUploadState({
    this.items = const [],
    this.isUploading = false,
    this.isPicking = false,
    this.overallProgress = 0.0,
    this.errorMessage,
    this.successMessage,
  });

  bool get hasItems => items.isNotEmpty;
  int get totalCount => items.length;
  int get uploadedCount => items.where((i) => i.isUploaded).length;
  int get pendingUploadCount =>
      items.where((i) => i.status == GalleryImageStatus.idle || i.status == GalleryImageStatus.error).length;
  bool get hasPendingUploads => pendingUploadCount > 0;
  bool get allUploaded => hasItems && items.every((i) => i.isUploaded);

  /// Converts current ordered gallery items into WooCommerce [ProductImageRef]s.
  List<ProductImageRef> toProductImageRefs() {
    return items
        .where((i) => i.isUploaded)
        .map((i) => i.toProductImageRef())
        .toList();
  }

  GalleryUploadState copyWith({
    List<GalleryImageItem>? items,
    bool? isUploading,
    bool? isPicking,
    double? overallProgress,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return GalleryUploadState(
      items: items ?? this.items,
      isUploading: isUploading ?? this.isUploading,
      isPicking: isPicking ?? this.isPicking,
      overallProgress: overallProgress ?? this.overallProgress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        items,
        isUploading,
        isPicking,
        overallProgress,
        errorMessage,
        successMessage,
      ];
}
