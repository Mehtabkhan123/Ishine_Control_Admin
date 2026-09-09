import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A CORS-resilient network image widget designed for Flutter Web & all platforms.
///
/// On Flutter Web, standard byte-fetching ([WebHtmlElementStrategy.never]) triggers
/// CORS exceptions (`statusCode: 0`) when the remote host (e.g., WordPress/WooCommerce)
/// does not send `Access-Control-Allow-Origin` headers.
///
/// [SafeNetworkImage] resolves this by configuring [WebHtmlElementStrategy.prefer],
/// which tells the Flutter Web engine to display the image using native HTML `<img>`
/// elements (which are not restricted by CORS). It also includes graceful error
/// fallback handling and loading states.
class SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUrl = imageUrl.trim();

    if (cleanUrl.isEmpty) {
      return _buildErrorWidget();
    }

    return Image.network(
      cleanUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            Container(
              width: width,
              height: height,
              color: AppColors.primary.withValues(alpha: 0.05),
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorWidget();
      },
    );
  }

  Widget _buildErrorWidget() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.grey.withValues(alpha: 0.12),
          child: const Center(
            child: Icon(
              Icons.broken_image_rounded,
              size: 22,
              color: Colors.grey,
            ),
          ),
        );
  }
}
