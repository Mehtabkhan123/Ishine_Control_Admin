import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration manager for environment variables loaded via flutter_dotenv.
class EnvConfig {
  EnvConfig._();

  static const String _keyBaseUrl = 'WOOCOMMERCE_BASE_URL';
  static const String _keyConsumerKey = 'WOOCOMMERCE_CONSUMER_KEY';
  static const String _keyConsumerSecret = 'WOOCOMMERCE_CONSUMER_SECRET';

  /// Initializes the environment configuration by loading [.env].
  static Future<void> init({String fileName = '.env'}) async {
    await dotenv.load(fileName: fileName);
  }

  /// The base URL of the WooCommerce store (e.g. https://example.com).
  static String get baseUrl {
    final rawUrl = dotenv.env[_keyBaseUrl] ?? '';
    return rawUrl.endsWith('/') ? rawUrl.substring(0, rawUrl.length - 1) : rawUrl;
  }

  /// The WooCommerce REST API Consumer Key (ck_...).
  static String get consumerKey => dotenv.env[_keyConsumerKey] ?? '';

  /// The WooCommerce REST API Consumer Secret (cs_...).
  static String get consumerSecret => dotenv.env[_keyConsumerSecret] ?? '';

  static const String _keyWordpressUsername = 'WORDPRESS_USERNAME';
  static const String _keyWordpressAppPassword = 'WORDPRESS_APP_PASSWORD';

  static String? _customWordpressUsername;
  static String? _customWordpressAppPassword;

  /// The WordPress Administrator Username (optional for Media API).
  static String get wordpressUsername =>
      _customWordpressUsername ?? dotenv.env[_keyWordpressUsername] ?? '';

  /// The WordPress Application Password (optional for Media API).
  static String get wordpressAppPassword =>
      _customWordpressAppPassword ?? dotenv.env[_keyWordpressAppPassword] ?? '';

  /// Sets or clears dynamic in-memory WordPress Application Password credentials.
  static void setWordpressCredentials({String? username, String? appPassword}) {
    _customWordpressUsername = username;
    _customWordpressAppPassword = appPassword;
  }

  /// Returns whether a dedicated WordPress Application Password is configured.
  static bool get hasWordpressAppPassword =>
      wordpressUsername.isNotEmpty && wordpressAppPassword.isNotEmpty;

  /// Returns whether all mandatory WooCommerce credentials have been configured.
  static bool get isConfigured =>
      baseUrl.isNotEmpty && consumerKey.isNotEmpty && consumerSecret.isNotEmpty;

  /// Returns a masked representation of the Consumer Key for safe UI display.
  static String get maskedConsumerKey {
    if (consumerKey.length <= 8) return '****';
    return '${consumerKey.substring(0, 6)}...${consumerKey.substring(consumerKey.length - 4)}';
  }
}
