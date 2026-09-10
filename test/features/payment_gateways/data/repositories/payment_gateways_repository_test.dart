import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/payment_gateways/data/models/get_payment_gateways_model.dart';
import 'package:ishine_admin_app/features/payment_gateways/data/models/put_update_payment_gateways_model.dart';
import 'package:ishine_admin_app/features/payment_gateways/data/repositories/payment_gateways_repository.dart';
import 'package:ishine_admin_app/features/payment_gateways/data/services/payment_gateways_service.dart';
import 'package:ishine_admin_app/features/system_status/data/services/system_status_service.dart';
import 'package:mocktail/mocktail.dart';

class MockPaymentGatewaysService extends Mock implements PaymentGatewaysService {}

void main() {
  late MockPaymentGatewaysService mockService;
  late PaymentGatewaysRepository repository;

  setUpAll(() {
    registerFallbackValue(WooCommerceAuthMode.auto);
  });

  final sampleGateways = [
    GetPaymentGatewaysModel(id: 'bacs', title: 'Bank Transfer', enabled: true),
    GetPaymentGatewaysModel(id: 'cod', title: 'Cash on Delivery', enabled: false),
  ];

  setUp(() {
    mockService = MockPaymentGatewaysService();
    repository = PaymentGatewaysRepository(service: mockService);
  });

  group('PaymentGatewaysRepository', () {
    test('getPaymentGateways caches response and does not invoke service twice',
        () async {
      when(() => mockService.fetchPaymentGateways(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => sampleGateways);

      final res1 = await repository.getPaymentGateways();
      expect(res1.length, 2);

      final res2 = await repository.getPaymentGateways();
      expect(res2.length, 2);

      verify(() => mockService.fetchPaymentGateways(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('getPaymentGateways with forceRefresh queries service again', () async {
      when(() => mockService.fetchPaymentGateways(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => sampleGateways);

      await repository.getPaymentGateways();
      await repository.getPaymentGateways(forceRefresh: true);

      verify(() => mockService.fetchPaymentGateways(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).called(2);
    });

    test('deduplicates concurrent in-flight requests', () async {
      when(() => mockService.fetchPaymentGateways(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return sampleGateways;
      });

      final f1 = repository.getPaymentGateways();
      final f2 = repository.getPaymentGateways();
      final f3 = repository.getPaymentGateways();

      final results = await Future.wait([f1, f2, f3]);

      expect(results[0].length, 2);
      expect(results[1].length, 2);
      expect(results[2].length, 2);

      verify(() => mockService.fetchPaymentGateways(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('getPaymentGateway retrieves single gateway and caches it', () async {
      final sampleGateway =
          GetPaymentGatewaysModel(id: 'bacs', title: 'Bank Transfer', enabled: true);

      when(() => mockService.fetchPaymentGateway('bacs'))
          .thenAnswer((_) async => sampleGateway);

      final g1 = await repository.getPaymentGateway('bacs');
      final g2 = await repository.getPaymentGateway('bacs');

      expect(g1.id, 'bacs');
      expect(g2.id, 'bacs');

      verify(() => mockService.fetchPaymentGateway('bacs')).called(1);
    });

    test('clearCache invalidates cached gateways', () async {
      when(() => mockService.fetchPaymentGateways(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => sampleGateways);

      await repository.getPaymentGateways();
      repository.clearCache();
      await repository.getPaymentGateways();

      verify(() => mockService.fetchPaymentGateways(
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).called(2);
    });

    test('updatePaymentGateway delegates to service and updates local cache', () async {
      final updatedModel = PutUpdatePaymentGatewaysModel(
        id: 'bacs',
        title: 'Updated Title',
        enabled: false,
      );

      when(() => mockService.updatePaymentGateway(
            id: 'bacs',
            data: any(named: 'data'),
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => updatedModel);

      final result = await repository.updatePaymentGateway(
        id: 'bacs',
        data: {'title': 'Updated Title', 'enabled': false},
      );

      expect(result.id, 'bacs');
      expect(result.title, 'Updated Title');
      expect(result.enabled, false);

      verify(() => mockService.updatePaymentGateway(
            id: 'bacs',
            data: any(named: 'data'),
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });
  });
}
