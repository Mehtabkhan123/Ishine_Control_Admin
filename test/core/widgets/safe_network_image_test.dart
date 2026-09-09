import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/widgets/safe_network_image.dart';

void main() {
  group('SafeNetworkImage Widget Tests', () {
    testWidgets('renders errorWidget when imageUrl is empty', (tester) async {
      const errorKey = Key('custom_error_widget');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafeNetworkImage(
              imageUrl: '',
              errorWidget: SizedBox(key: errorKey),
            ),
          ),
        ),
      );

      expect(find.byKey(errorKey), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('renders errorWidget when imageUrl is only whitespace', (tester) async {
      const errorKey = Key('custom_error_widget');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafeNetworkImage(
              imageUrl: '   ',
              errorWidget: SizedBox(key: errorKey),
            ),
          ),
        ),
      );

      expect(find.byKey(errorKey), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('renders default broken image icon when imageUrl is empty and no errorWidget is given', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafeNetworkImage(
              imageUrl: '',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.broken_image_rounded), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('creates Image.network with WebHtmlElementStrategy.prefer and trimmed URL', (tester) async {
      const url = '  https://darkgrey-albatross-869937.hostingersite.com/test.webp  ';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafeNetworkImage(
              imageUrl: url,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final imageWidget = tester.widget<Image>(imageFinder);
      expect(imageWidget.image, isA<NetworkImage>());
      final networkImage = imageWidget.image as NetworkImage;
      expect(networkImage.url, equals('https://darkgrey-albatross-869937.hostingersite.com/test.webp'));
      expect(networkImage.webHtmlElementStrategy, equals(WebHtmlElementStrategy.prefer));
      expect(imageWidget.width, equals(48));
      expect(imageWidget.height, equals(48));
      expect(imageWidget.fit, equals(BoxFit.cover));
    });
  });
}
