import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'post_create_model.dart';

/// Status of a gallery image during selection and upload lifecycle.
enum GalleryImageStatus {
  idle,
  uploading,
  success,
  error,
}

/// Represents a single product gallery image item, supporting both locally picked
/// device files and remote WooCommerce product images with reordering and upload states.
class GalleryImageItem extends Equatable {
  final String uniqueId;
  final int? id;
  final String? remoteUrl;
  final String? localPath;
  final Uint8List? bytes;
  final String name;
  final int size;
  final GalleryImageStatus status;
  final double progress;
  final String? errorMessage;

  const GalleryImageItem({
    required this.uniqueId,
    this.id,
    this.remoteUrl,
    this.localPath,
    this.bytes,
    required this.name,
    this.size = 0,
    this.status = GalleryImageStatus.idle,
    this.progress = 0.0,
    this.errorMessage,
  });

  bool get isUploaded =>
      status == GalleryImageStatus.success &&
      ((remoteUrl != null && remoteUrl!.isNotEmpty) || (id != null && id! > 0));

  bool get isUploading => status == GalleryImageStatus.uploading;
  bool get hasError => status == GalleryImageStatus.error;

  /// Converts to WooCommerce [ProductImageRef] for payload submission.
  ProductImageRef toProductImageRef() {
    return ProductImageRef(
      id: id,
      src: remoteUrl,
      name: name,
    );
  }

  /// Creates a [GalleryImageItem] from an existing WooCommerce [ProductImageRef].
  factory GalleryImageItem.fromProductImageRef(ProductImageRef ref, {int index = 0}) {
    return GalleryImageItem(
      uniqueId: 'existing_${ref.id ?? index}_${DateTime.now().microsecondsSinceEpoch}',
      id: ref.id,
      remoteUrl: ref.src,
      name: ref.name ?? 'Image ${index + 1}',
      status: GalleryImageStatus.success,
      progress: 1.0,
    );
  }

  GalleryImageItem copyWith({
    int? id,
    String? remoteUrl,
    String? localPath,
    Uint8List? bytes,
    String? name,
    int? size,
    GalleryImageStatus? status,
    double? progress,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GalleryImageItem(
      uniqueId: uniqueId,
      id: id ?? this.id,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      localPath: localPath ?? this.localPath,
      bytes: bytes ?? this.bytes,
      name: name ?? this.name,
      size: size ?? this.size,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        uniqueId,
        id,
        remoteUrl,
        localPath,
        name,
        size,
        status,
        progress,
        errorMessage,
      ];
}
