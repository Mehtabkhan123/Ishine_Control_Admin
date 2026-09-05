import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/system_status/data/models/system_status_model.dart';

void main() {
  group('SystemStatus Model', () {
    test('parses WooCommerce system_status JSON successfully', () {
      final json = {
        'environment': {
          'home_url': 'https://darkgrey-albatross-869937.hostingersite.com',
          'site_url': 'https://darkgrey-albatross-869937.hostingersite.com',
          'version': '9.4.0',
          'wp_version': '6.7.1',
          'php_version': '8.2.20',
          'server_info': 'LiteSpeed',
          'mysql_version_string': '10.11.8-MariaDB',
          'secure_connection': true,
          'wp_debug_mode': false,
        },
        'settings': {
          'currency': 'USD',
          'currency_symbol': '\$',
        },
        'security': {
          'secure_connection': true,
        },
        'theme': {
          'name': 'Astra',
          'version': '4.8.0',
        },
        'active_plugins': [
          {'name': 'WooCommerce', 'version': '9.4.0'},
          {'name': 'Elementor', 'version': '3.25.0'},
        ],
      };

      final status = SystemStatus.fromJson(json, responseTimeMs: 145);

      expect(status.siteUrl, 'https://darkgrey-albatross-869937.hostingersite.com');
      expect(status.wcVersion, '9.4.0');
      expect(status.wpVersion, '6.7.1');
      expect(status.phpVersion, '8.2.20');
      expect(status.serverInfo, 'LiteSpeed');
      expect(status.mysqlVersion, '10.11.8-MariaDB');
      expect(status.isSecure, true);
      expect(status.isDebugMode, false);
      expect(status.currency, 'USD');
      expect(status.currencySymbol, '\$');
      expect(status.activePluginsCount, 2);
      expect(status.themeName, 'Astra');
      expect(status.themeVersion, '4.8.0');
      expect(status.responseTimeMs, 145);
    });
  });
}
