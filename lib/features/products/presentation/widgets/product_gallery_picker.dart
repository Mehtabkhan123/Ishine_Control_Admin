import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/gallery_upload_cubit.dart';
import '../../bloc/gallery_upload_state.dart';
import '../../data/models/gallery_image_item.dart';
import '../../data/models/post_create_model.dart';

/// Samsung One UI-inspired Product Gallery Picker widget.
/// Allows admins to pick multiple images from device gallery, preview them instantly,
/// reorder them, monitor upload progress, and attach them to the WooCommerce product.
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
          final isCredentialError = state.errorMessage!.contains('WordPress') ||
              state.errorMessage!.contains('401') ||
              state.errorMessage!.contains('credentials') ||
              state.errorMessage!.contains('Application Password') ||
              state.errorMessage!.contains('unauthorized');

          ScaffoldMessenger.of(context).showSnackBar(
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
                label: isCredentialError ? 'Setup WP' : 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  if (isCredentialError) {
                    _showWordpressCredentialDialog(context);
                  } else {
                    context.read<GalleryUploadCubit>().uploadPending();
                  }
                },
              ),
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

              // Action Buttons (Pick from Gallery / Camera / Upload)
              _buildActionToolbar(context, cubit, state, isDark),

              // WordPress Credentials Setup Banner (shown when not configured)
              if (!EnvConfig.hasWordpressAppPassword) ...[
                const SizedBox(height: 14),
                _buildCredentialsBanner(context, isDark),
              ],

              // Overall Upload Progress Bar
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
                'First photo is the main storefront cover. Reorder with arrows or star button.',
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
        FilledButton.icon(
          onPressed: state.isPicking || state.isUploading
              ? null
              : () => cubit.pickFromGallery(),
          icon: state.isPicking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.add_photo_alternate_rounded, size: 18),
          label: const Text('Select from Gallery'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: state.isPicking || state.isUploading
              ? null
              : () => cubit.captureFromCamera(),
          icon: const Icon(Icons.camera_alt_rounded, size: 18),
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
        if (state.hasPendingUploads && !state.isUploading)
          FilledButton.tonalIcon(
            onPressed: () => cubit.uploadPending(),
            icon: const Icon(Icons.cloud_upload_rounded, size: 18),
            label: Text('Upload Pending (${state.pendingUploadCount})'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent.withValues(alpha: 0.15),
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  'Uploading gallery images to WordPress...',
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
            value: state.overallProgress,
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
    return InkWell(
      onTap: () => cubit.pickFromGallery(),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
              'No product images selected',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap here or use the button above to pick images from your gallery.',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
                const SizedBox(height: 2),

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
      return Image.network(
        item.remoteUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
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
              'Attached',
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
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Ready',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.warning,
        ),
      ),
    );
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildCredentialsBanner(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.key_rounded,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WordPress Media Credentials',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Configure WordPress credentials to upload images directly to store media library.',
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
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () => _showWordpressCredentialDialog(context),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Setup', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showWordpressCredentialDialog(BuildContext context) {
    final userController = TextEditingController(text: EnvConfig.wordpressUsername);
    final passController = TextEditingController(text: EnvConfig.wordpressAppPassword);
    bool obscure = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'WordPress Credentials',
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
                    'WordPress requires an Application Password to upload media attachments directly to /wp-json/wp/v2/media.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How to get your Application Password:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '1. Log into WP Admin > Users > Profile\n'
                          '2. Scroll to "Application Passwords"\n'
                          '3. Type "Admin App" and click "Add New"\n'
                          '4. Copy the generated 24-character password and paste below.',
                          style: TextStyle(fontSize: 11, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: userController,
                    decoration: InputDecoration(
                      labelText: 'WordPress Username / Email',
                      hintText: 'e.g. admin or your username',
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Application Password',
                      hintText: 'xxxx xxxx xxxx xxxx xxxx xxxx',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(() => obscure = !obscure),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
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
                  final u = userController.text.trim();
                  final p = passController.text.trim();
                  if (u.isNotEmpty && p.isNotEmpty) {
                    EnvConfig.setWordpressCredentials(username: u, appPassword: p);
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    final cubit = context.read<GalleryUploadCubit>();
                    Navigator.of(dialogCtx).pop();
                    messenger?.showSnackBar(
                      const SnackBar(
                        content: Text('WordPress credentials saved! Uploading pending images...'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    cubit.uploadPending();
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Save & Upload'),
              ),
            ],
          );
        },
      ),
    );
  }
}
