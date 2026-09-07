import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/gallery_image_item.dart';
import '../data/models/post_create_model.dart';
import '../data/repositories/products_repository.dart';
import 'gallery_upload_state.dart';

/// Cubit managing product gallery image selection, previews, reordering,
/// and uploading to the WordPress/WooCommerce media repository.
class GalleryUploadCubit extends Cubit<GalleryUploadState> {
  final ProductsRepository repository;
  final ImagePicker _imagePicker;

  GalleryUploadCubit({
    required this.repository,
    ImagePicker? imagePicker,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        super(const GalleryUploadState());

  /// Seeds existing product images when editing an existing product.
  void setInitialImages(List<ProductImageRef>? images) {
    if (images == null || images.isEmpty) {
      emit(const GalleryUploadState());
      return;
    }

    final items = images.asMap().entries.map((entry) {
      return GalleryImageItem.fromProductImageRef(entry.value, index: entry.key);
    }).toList();

    emit(state.copyWith(
      items: items,
      clearError: true,
      clearSuccess: true,
    ));
  }

  /// Opens the device gallery allowing multi-selection of product images.
  Future<void> pickFromGallery({bool autoUpload = true}) async {
    emit(state.copyWith(isPicking: true, clearError: true));

    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage();
      if (pickedFiles.isEmpty) {
        emit(state.copyWith(isPicking: false));
        return;
      }

      final List<GalleryImageItem> newItems = [];
      final currentTimestamp = DateTime.now().millisecondsSinceEpoch;

      for (int i = 0; i < pickedFiles.length; i++) {
        final file = pickedFiles[i];
        final bytes = await file.readAsBytes();
        final filename = file.name.isNotEmpty ? file.name : 'product_image_${currentTimestamp}_$i.jpg';

        newItems.add(
          GalleryImageItem(
            uniqueId: 'local_${currentTimestamp}_$i',
            localPath: file.path,
            bytes: bytes,
            name: filename,
            size: bytes.length,
            status: GalleryImageStatus.idle,
            progress: 0.0,
          ),
        );
      }

      final updatedItems = List<GalleryImageItem>.from(state.items)..addAll(newItems);
      emit(state.copyWith(
        items: updatedItems,
        isPicking: false,
        clearError: true,
      ));

      if (autoUpload) {
        await uploadPending();
      }
    } catch (e) {
      emit(state.copyWith(
        isPicking: false,
        errorMessage: 'Failed to pick images from device gallery: ${e.toString()}',
      ));
    }
  }

  /// Captures a new photo using the device camera.
  Future<void> captureFromCamera({bool autoUpload = true}) async {
    emit(state.copyWith(isPicking: true, clearError: true));

    try {
      final XFile? file = await _imagePicker.pickImage(source: ImageSource.camera);
      if (file == null) {
        emit(state.copyWith(isPicking: false));
        return;
      }

      final bytes = await file.readAsBytes();
      final currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = file.name.isNotEmpty ? file.name : 'photo_$currentTimestamp.jpg';

      final newItem = GalleryImageItem(
        uniqueId: 'camera_$currentTimestamp',
        localPath: file.path,
        bytes: bytes,
        name: filename,
        size: bytes.length,
        status: GalleryImageStatus.idle,
        progress: 0.0,
      );

      final updatedItems = List<GalleryImageItem>.from(state.items)..add(newItem);
      emit(state.copyWith(
        items: updatedItems,
        isPicking: false,
        clearError: true,
      ));

      if (autoUpload) {
        await uploadPending();
      }
    } catch (e) {
      emit(state.copyWith(
        isPicking: false,
        errorMessage: 'Failed to capture photo: ${e.toString()}',
      ));
    }
  }

  /// Removes an image from the gallery at the given [index].
  void removeImage(int index) {
    if (index < 0 || index >= state.items.length) return;

    final updatedItems = List<GalleryImageItem>.from(state.items)..removeAt(index);
    emit(state.copyWith(items: updatedItems));
  }

  /// Reorders images when dragging inside a reorderable list.
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.items.length) return;
    if (newIndex < 0 || newIndex > state.items.length) return;

    final updated = List<GalleryImageItem>.from(state.items);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);

    emit(state.copyWith(items: updated));
  }

  /// Moves the image at [index] one position to the left.
  void moveLeft(int index) {
    if (index <= 0 || index >= state.items.length) return;
    final updated = List<GalleryImageItem>.from(state.items);
    final temp = updated[index];
    updated[index] = updated[index - 1];
    updated[index - 1] = temp;
    emit(state.copyWith(items: updated));
  }

  /// Moves the image at [index] one position to the right.
  void moveRight(int index) {
    if (index < 0 || index >= state.items.length - 1) return;
    final updated = List<GalleryImageItem>.from(state.items);
    final temp = updated[index];
    updated[index] = updated[index + 1];
    updated[index + 1] = temp;
    emit(state.copyWith(items: updated));
  }

  /// Sets the selected image as the main featured image (index 0).
  void setAsMain(int index) {
    if (index <= 0 || index >= state.items.length) return;
    final updated = List<GalleryImageItem>.from(state.items);
    final item = updated.removeAt(index);
    updated.insert(0, item);
    emit(state.copyWith(items: updated));
  }

  /// Uploads all pending or failed local images to the server.
  Future<void> uploadPending() async {
    if (state.isUploading) return;

    final pendingIndices = <int>[];
    for (int i = 0; i < state.items.length; i++) {
      final item = state.items[i];
      if (!item.isUploaded && item.bytes != null && item.bytes!.isNotEmpty) {
        pendingIndices.add(i);
      }
    }

    if (pendingIndices.isEmpty) return;

    emit(state.copyWith(
      isUploading: true,
      overallProgress: 0.0,
      clearError: true,
    ));

    int completedCount = 0;
    String? firstErrorMessage;

    for (final index in pendingIndices) {
      final currentItem = state.items[index];

      // Mark item as uploading
      final uploadingItems = List<GalleryImageItem>.from(state.items);
      uploadingItems[index] = currentItem.copyWith(
        status: GalleryImageStatus.uploading,
        progress: 0.0,
        clearError: true,
      );
      emit(state.copyWith(items: uploadingItems));

      try {
        final uploadedRef = await repository.uploadMedia(
          bytes: currentItem.bytes!,
          filename: currentItem.name,
          onProgress: (p) {
            final progressItems = List<GalleryImageItem>.from(state.items);
            if (index < progressItems.length) {
              progressItems[index] = progressItems[index].copyWith(progress: p);
              final overall = (completedCount + p) / pendingIndices.length;
              emit(state.copyWith(items: progressItems, overallProgress: overall));
            }
          },
        );

        // Mark item as success
        final successItems = List<GalleryImageItem>.from(state.items);
        successItems[index] = successItems[index].copyWith(
          id: uploadedRef.id,
          remoteUrl: uploadedRef.src,
          status: GalleryImageStatus.success,
          progress: 1.0,
          clearError: true,
        );
        completedCount++;
        final overall = completedCount / pendingIndices.length;
        emit(state.copyWith(
          items: successItems,
          overallProgress: overall,
        ));
      } catch (e) {
        firstErrorMessage ??= e.toString();
        final errorItems = List<GalleryImageItem>.from(state.items);
        errorItems[index] = errorItems[index].copyWith(
          status: GalleryImageStatus.error,
          errorMessage: e.toString(),
        );
        emit(state.copyWith(items: errorItems));
      }
    }

    emit(state.copyWith(
      isUploading: false,
      errorMessage: firstErrorMessage,
      successMessage: completedCount > 0 ? 'Uploaded $completedCount image(s) to product gallery.' : null,
    ));
  }

  /// Retries uploading a specific image by index.
  Future<void> retryUpload(int index) async {
    if (index < 0 || index >= state.items.length) return;
    final item = state.items[index];
    if (item.bytes == null || item.bytes!.isEmpty) return;

    final updated = List<GalleryImageItem>.from(state.items);
    updated[index] = item.copyWith(
      status: GalleryImageStatus.idle,
      progress: 0.0,
      clearError: true,
    );
    emit(state.copyWith(items: updated));

    await uploadPending();
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}
