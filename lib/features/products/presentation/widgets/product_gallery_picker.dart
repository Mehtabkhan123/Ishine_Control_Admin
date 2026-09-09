import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../bloc/gallery_upload_cubit.dart';
import '../../bloc/gallery_upload_state.dart';
import '../../data/models/gallery_image_item.dart';
import '../../data/models/post_create_model.dart';

/// Samsung One UI-inspired Product Gallery Picker widget.
///
/// Supports the official WooCommerce product-image workflow:
/// 1. Attaching images via direct image URL (WooCommerce natively downloads and attaches them).
/// 2. Selecting device gallery images for local preview and reordering.
/// 3. Setting main cover photo, reordering, and deleting images.
/// 4. Graceful error handling without crashing the product screen.
class ProductGalleryPicker extends StatelessWidget {
  final bool isDark;
  final ValueChanged<List<ProductImageRef>>? onImagesChanged;

  const ProductGalleryPicker({
    super.key,
    required this.isDark,
    this.onImagesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GalleryUploadCubit, GalleryUploadState>(
      listener: (context, state) {
        if (onImagesChanged != null) {
          onImagesChanged!(state.toProductImageRefs());
        }

        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
                },
              ),
            ),
          );
        }

        if (state.successMessage != null && state.successMessage!.isNotEmpty) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.successMessage!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<GalleryUploadCubit>();

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              _buildHeader(context, state, isDark),
              const SizedBox(height: 16),

              // Action Toolbar (Add via URL / Device Gallery / Camera)
              _buildActionToolbar(context, cubit, state, isDark),

              // Overall Upload Progress Bar (if upload in progress)
              if (state.isUploading) ...[
                const SizedBox(height: 14),
                _buildOverallProgressIndicator(state, isDark),
              ],

              const SizedBox(height: 18),

              // Image Gallery Previews Grid or Empty State
              if (state.items.isEmpty)
                _buildEmptyState(context, cubit, isDark)
              else
                _buildGalleryGrid(context, cubit, state, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    GalleryUploadState state,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.photo_library_rounded,
            size: 20,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Product Gallery',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${state.totalCount} ${state.totalCount == 1 ? 'image' : 'images'}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'First photo is the main storefront cover. Add via Image URL or select from device.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionToolbar(
    BuildContext context,
    GalleryUploadCubit cubit,
    GalleryUploadState state,
    bool isDark,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        // Store Media Library (Existing images on WooCommerce store)
        FilledButton.icon(
          onPressed: state.isPicking || state.isUploading
              ? null
              : () => _showMediaLibraryDialog(context, cubit),
          icon: const Icon(Icons.cloud_done_rounded, size: 18),
          label: const Text('Store Media Library'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F766E), // Deep Teal
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        // Add via URL (Primary supported WooCommerce workflow)
        FilledButton.icon(
          onPressed: state.isPicking || state.isUploading
              ? null
              : () => _showAddUrlDialog(context, cubit),
          icon: const Icon(Icons.add_link_rounded, size: 18),
          label: const Text('Add Image URL'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        // Device Gallery (Image selection)
        OutlinedButton.icon(
          onPressed: state.isPicking || state.isUploading
              ? null
              : () => _pickFromGalleryWithPrompt(context, cubit),
          icon: state.isPicking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.photo_library_outlined, size: 18),
          label: const Text('Device Gallery'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
        ),

        // Camera (Capture photo)
        OutlinedButton.icon(
          onPressed: state.isPicking || state.isUploading
              ? null
              : () => _captureFromCameraWithPrompt(context, cubit),
          icon: const Icon(Icons.camera_alt_outlined, size: 18),
          label: const Text('Take Photo'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
        ),

        // Optional retry for pending uploads
        if (state.hasPendingUploads && !state.isUploading)
          FilledButton.tonalIcon(
            onPressed: () => cubit.uploadPending(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('Retry Upload (${state.pendingUploadCount})'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent.withValues(alpha: 0.15),
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOverallProgressIndicator(GalleryUploadState state, bool isDark) {
    final percent = (state.overallProgress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Processing gallery images...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: state.overallProgress > 0 ? state.overallProgress : null,
            minHeight: 6,
            backgroundColor: isDark
                ? AppColors.darkBackground
                : const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    GalleryUploadCubit cubit,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBackground.withValues(alpha: 0.5)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_photo_alternate_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No gallery images attached',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Add images via direct URL (supported by WooCommerce) or select from device gallery.',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => _showMediaLibraryDialog(context, cubit),
                icon: const Icon(Icons.cloud_done_rounded, size: 16),
                label: const Text('Store Media Library'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showAddUrlDialog(context, cubit),
                icon: const Icon(Icons.add_link_rounded, size: 16),
                label: const Text('Add via URL'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickFromGalleryWithPrompt(context, cubit),
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: const Text('Choose from Gallery'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid(
    BuildContext context,
    GalleryUploadCubit cubit,
    GalleryUploadState state,
    bool isDark,
  ) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: state.items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isMain = index == 0;

        return _buildImageCard(
          context: context,
          cubit: cubit,
          item: item,
          index: index,
          totalCount: state.items.length,
          isMain: isMain,
          isDark: isDark,
        );
      }).toList(),
    );
  }

  Widget _buildImageCard({
    required BuildContext context,
    required GalleryUploadCubit cubit,
    required GalleryImageItem item,
    required int index,
    required int totalCount,
    required bool isMain,
    required bool isDark,
  }) {
    return Container(
      width: 145,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMain
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isMain ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Preview Container with Stack
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: SizedBox(
                  width: 145,
                  height: 120,
                  child: _buildImageThumbnail(item),
                ),
              ),

              // Main / Cover Badge
              if (isMain)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 3),
                        Text(
                          'Cover',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Delete Button
              Positioned(
                top: 6,
                right: 6,
                child: InkWell(
                  onTap: () => cubit.removeImage(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Uploading overlay with spinner
              if (item.isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${(item.progress * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Card Footer info & actions
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filename
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),

                // Status Badge & Size
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusChip(item),
                    if (item.size > 0)
                      Text(
                        _formatFileSize(item.size),
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                  ],
                ),

                // Link URL & Media Library chips for local images that haven't been linked yet
                if (!item.isUploaded && item.remoteUrl == null) ...[
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      InkWell(
                        onTap: () => _showLinkUrlDialog(context, cubit, index, item.name),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.link_rounded, size: 10, color: AppColors.primary),
                              SizedBox(width: 3),
                              Text(
                                'Link URL',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _showMediaLibraryDialog(context, cubit, targetIndex: index),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_library_rounded, size: 10, color: Color(0xFF0F766E)),
                              SizedBox(width: 3),
                              Text(
                                'Media',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 6),

                // Reordering Action Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Move Left
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 12),
                      onPressed: index > 0 ? () => cubit.moveLeft(index) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 26,
                        minHeight: 26,
                      ),
                      tooltip: 'Move Left',
                    ),

                    // Star / Set Main
                    if (!isMain)
                      IconButton(
                        icon: const Icon(Icons.star_outline_rounded, size: 15),
                        onPressed: () => cubit.setAsMain(index),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 26,
                          minHeight: 26,
                        ),
                        color: AppColors.warning,
                        tooltip: 'Set as Cover Photo',
                      )
                    else
                      const Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: AppColors.warning,
                      ),

                    // Move Right
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                      ),
                      onPressed: index < totalCount - 1
                          ? () => cubit.moveRight(index)
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 26,
                        minHeight: 26,
                      ),
                      tooltip: 'Move Right',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(GalleryImageItem item) {
    if (item.bytes != null && item.bytes!.isNotEmpty) {
      return Image.memory(
        item.bytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image_rounded, size: 28, color: Colors.grey),
        ),
      );
    }

    if (item.remoteUrl != null && item.remoteUrl!.isNotEmpty) {
      return SafeNetworkImage(
        imageUrl: item.remoteUrl!,
        fit: BoxFit.cover,
        errorWidget: const Center(
          child: Icon(Icons.broken_image_rounded, size: 28, color: Colors.grey),
        ),
      );
    }

    return Container(
      color: Colors.grey.withValues(alpha: 0.2),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 28, color: Colors.grey),
      ),
    );
  }

  Widget _buildStatusChip(GalleryImageItem item) {
    if (item.isUploaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 10,
              color: AppColors.success,
            ),
            SizedBox(width: 3),
            Text(
              'Ready',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    if (item.isUploading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Uploading...',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (item.hasError) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Failed',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.error,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 10,
            color: AppColors.warning,
          ),
          SizedBox(width: 3),
          Text(
            'Link Needed',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Dialog allowing the admin to add a product image via direct URL.
  /// Supports live preview before adding to verify the URL is valid.
  void _showAddUrlDialog(BuildContext context, GalleryUploadCubit cubit) {
    if (!context.mounted) return;

    final urlController = TextEditingController();
    final nameController = TextEditingController();
    String previewUrl = '';
    String? validationError;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final hasValidPreview = previewUrl.startsWith('http://') ||
              previewUrl.startsWith('https://');

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_link_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Add Image via URL',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter a direct public image link (JPEG, PNG, WebP). WooCommerce will automatically download and attach this image to your product.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Image URL input field
                  TextFormField(
                    controller: urlController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Image URL *',
                      hintText: 'https://example.com/product-photo.jpg',
                      errorText: validationError,
                      prefixIcon: const Icon(Icons.link_rounded, size: 20),
                      suffixIcon: urlController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                urlController.clear();
                                setState(() {
                                  previewUrl = '';
                                  validationError = null;
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        previewUrl = val.trim();
                        if (validationError != null) validationError = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Optional Image Name
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Image Label (Optional)',
                      hintText: 'e.g. Front View, Product Angle',
                      prefixIcon: const Icon(Icons.label_outline_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),

                  // Live Preview Box
                  if (hasValidPreview) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 54,
                              height: 54,
                              child: SafeNetworkImage(
                                imageUrl: previewUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Live Preview',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  previewUrl,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final rawUrl = urlController.text.trim();
                  if (rawUrl.isEmpty) {
                    setState(() {
                      validationError = 'Image URL cannot be empty';
                    });
                    return;
                  }

                  if (!rawUrl.startsWith('http://') &&
                      !rawUrl.startsWith('https://')) {
                    setState(() {
                      validationError = 'URL must start with https:// or http://';
                    });
                    return;
                  }

                  final customName = nameController.text.trim();
                  cubit.addImageUrl(
                    rawUrl,
                    name: customName.isNotEmpty ? customName : null,
                  );
                  Navigator.of(dialogCtx).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Add to Gallery'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Dialog allowing admin to link a remote URL to an existing local image in the grid.
  void _showLinkUrlDialog(
    BuildContext context,
    GalleryUploadCubit cubit,
    int index,
    String currentName,
  ) {
    if (!context.mounted) return;

    final urlController = TextEditingController();
    String? validationError;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.link_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Link Image URL',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Link a hosted or CDN URL for "$currentName". WooCommerce will use this URL when saving your product.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: urlController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Public Image URL *',
                    hintText: 'https://...',
                    errorText: validationError,
                    prefixIcon: const Icon(Icons.link_rounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (val) {
                    if (validationError != null) {
                      setState(() => validationError = null);
                    }
                  },
                ),
                const SizedBox(height: 14),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(dialogCtx).pop();
                      _showMediaLibraryDialog(context, cubit, targetIndex: index);
                    },
                    icon: const Icon(
                      Icons.cloud_done_rounded,
                      size: 16,
                      color: Color(0xFF0F766E),
                    ),
                    label: const Text(
                      'Or Pick from Store Media Library',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0F766E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0F766E)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final url = urlController.text.trim();
                  if (url.isEmpty) {
                    setState(() => validationError = 'URL cannot be empty');
                    return;
                  }
                  if (!url.startsWith('http://') && !url.startsWith('https://')) {
                    setState(() => validationError = 'URL must start with https:// or http://');
                    return;
                  }

                  cubit.setImageUrl(index, url);
                  Navigator.of(dialogCtx).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Link URL'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickFromGalleryWithPrompt(
    BuildContext context,
    GalleryUploadCubit cubit,
  ) async {
    await cubit.pickFromGallery(autoUpload: false);
    if (!context.mounted) return;

    if (cubit.state.hasUnlinkedItems) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Photo added! Link its Image URL or choose from Store Media Library to attach to WooCommerce.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Media Library',
            textColor: AppColors.primary,
            onPressed: () => _showMediaLibraryDialog(context, cubit),
          ),
        ),
      );
    }
  }

  Future<void> _captureFromCameraWithPrompt(
    BuildContext context,
    GalleryUploadCubit cubit,
  ) async {
    await cubit.captureFromCamera(autoUpload: false);
    if (!context.mounted) return;

    if (cubit.state.hasUnlinkedItems) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Photo captured! Link its Image URL or choose from Store Media Library to attach to WooCommerce.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Media Library',
            textColor: AppColors.primary,
            onPressed: () => _showMediaLibraryDialog(context, cubit),
          ),
        ),
      );
    }
  }

  /// Displays the Store Media Library dialog to pick existing images directly from WooCommerce/WordPress.
  void _showMediaLibraryDialog(
    BuildContext context,
    GalleryUploadCubit cubit, {
    int? targetIndex,
  }) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => _MediaLibraryDialog(
        cubit: cubit,
        targetIndex: targetIndex,
      ),
    );
  }
}

/// Dialog allowing admin to browse, search, and pick images already hosted on the store.
class _MediaLibraryDialog extends StatefulWidget {
  final GalleryUploadCubit cubit;
  final int? targetIndex;

  const _MediaLibraryDialog({
    required this.cubit,
    this.targetIndex,
  });

  @override
  State<_MediaLibraryDialog> createState() => _MediaLibraryDialogState();
}

class _MediaLibraryDialogState extends State<_MediaLibraryDialog> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<ProductImageRef> _items = [];
  final Set<ProductImageRef> _selected = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMedia({String? search}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await widget.cubit.loadMediaLibrary(search: search);
      if (mounted) {
        setState(() {
          _items = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSingleSelect = widget.targetIndex != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.cloud_done_rounded,
              color: Color(0xFF0F766E),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Store Media Library',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                Text(
                  isSingleSelect
                      ? 'Select an image to link to this slot'
                      : 'Choose images to attach to product gallery',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 480,
        child: Column(
          children: [
            // Search Box
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search media by title or filename...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _loadMedia();
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (query) => _loadMedia(search: query.trim()),
            ),
            const SizedBox(height: 14),

            // Content Area
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(strokeWidth: 2.5),
                          SizedBox(height: 12),
                          Text('Loading store images...',
                              style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: AppColors.error, size: 36),
                              const SizedBox(height: 8),
                              Text('Failed to load media: $_errorMessage',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => _loadMedia(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _items.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.photo_library_outlined,
                                    size: 40,
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'No media items found.',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              itemCount: _items.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.9,
                              ),
                              itemBuilder: (ctx, index) {
                                final media = _items[index];
                                final isSelected = _selected.contains(media);

                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isSingleSelect) {
                                        _selected.clear();
                                        _selected.add(media);
                                      } else {
                                        if (isSelected) {
                                          _selected.remove(media);
                                        } else {
                                          _selected.add(media);
                                        }
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF0F766E)
                                            : (isDark
                                                ? AppColors.darkBorder
                                                : AppColors.lightBorder),
                                        width: isSelected ? 2.5 : 1,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                  top: Radius.circular(10),
                                                ),
                                                child: SafeNetworkImage(
                                                  imageUrl: media.src ?? '',
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(6),
                                              child: Text(
                                                media.name ??
                                                    'Media #${media.id}',
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (isSelected)
                                          Positioned(
                                            top: 6,
                                            right: 6,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(3),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF0F766E),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check_rounded,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () {
                  if (isSingleSelect) {
                    widget.cubit.setMediaRef(
                      widget.targetIndex!,
                      _selected.first,
                    );
                  } else {
                    widget.cubit.addMediaRefs(_selected.toList());
                  }
                  Navigator.of(context).pop();
                },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F766E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            isSingleSelect
                ? 'Link Image'
                : 'Add to Gallery (${_selected.length})',
          ),
        ),
      ],
    );
  }
}

