import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/env_config.dart';
import 'core/network/dio_client.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/layout/presentation/widgets/admin_scaffold.dart';
import 'features/products/bloc/create_product_bloc.dart';
import 'features/products/bloc/update_product_bloc.dart';
import 'features/products/bloc/products_bloc.dart';
import 'features/products/bloc/products_event.dart';
import 'features/products/data/repositories/products_repository.dart';
import 'features/reports/bloc/sales_report_bloc.dart';
import 'features/reports/bloc/sales_report_event.dart';
import 'features/reports/bloc/top_sellers_bloc.dart';
import 'features/reports/bloc/top_sellers_event.dart';
import 'features/reports/data/repositories/reports_repository.dart';
import 'features/orders/data/repositories/orders_repository.dart';
import 'features/orders/bloc/single_order_cubit.dart';
import 'features/orders/bloc/update_order_cubit.dart';
import 'features/orders/bloc/delete_order_cubit.dart';
import 'features/customers/data/repositories/customers_repository.dart';
import 'features/customers/bloc/customers_bloc.dart';
import 'features/customers/bloc/customers_event.dart';
import 'features/customers/bloc/single_customer_cubit.dart';
import 'features/customers/bloc/update_customer_cubit.dart';
import 'features/customers/bloc/delete_customer_cubit.dart';
import 'features/coupons/data/repositories/coupons_repository.dart';
import 'features/coupons/bloc/coupons_bloc.dart';
import 'features/coupons/bloc/coupons_event.dart';
import 'features/coupons/bloc/create_coupon_cubit.dart';
import 'features/coupons/bloc/update_coupon_cubit.dart';
import 'features/coupons/bloc/delete_coupon_cubit.dart';
import 'features/shipping/data/repositories/shipping_repository.dart';
import 'features/shipping/bloc/shipping_zones_bloc.dart';
import 'features/shipping/bloc/shipping_zones_event.dart';
import 'features/taxes/data/repositories/taxes_repository.dart';
import 'features/taxes/bloc/tax_rates_bloc.dart';
import 'features/taxes/bloc/tax_rates_event.dart';
import 'features/taxes/bloc/create_tax_rate_cubit.dart';
import 'features/payment_gateways/data/repositories/payment_gateways_repository.dart';
import 'features/payment_gateways/bloc/payment_gateways_bloc.dart';
import 'features/payment_gateways/bloc/payment_gateways_event.dart';
import 'features/payment_gateways/bloc/update_payment_gateway_cubit.dart';
import 'features/settings/data/repositories/general_settings_repository.dart';
import 'features/settings/data/repositories/product_settings_repository.dart';
import 'features/settings/data/repositories/tax_settings_repository.dart';
import 'features/settings/bloc/general_settings_bloc.dart';
import 'features/settings/bloc/general_settings_event.dart';
import 'features/settings/bloc/product_settings_bloc.dart';
import 'features/settings/bloc/product_settings_event.dart';
import 'features/settings/bloc/tax_settings_bloc.dart';
import 'features/settings/bloc/tax_settings_event.dart';
import 'features/system_status/bloc/system_status_bloc.dart';
import 'features/system_status/bloc/system_status_event.dart';
import 'features/system_status/bloc/system_status_tools_bloc.dart';
import 'features/system_status/bloc/system_status_tools_event.dart';
import 'features/system_status/data/repositories/system_status_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load store credentials and config from .env

  try {
    await EnvConfig.init();
  } catch (e) {
    debugPrint('⚠️ Warning: Failed to load .env file: $e');
  }

  // Initialize Core Services & Repositories
  final dioClient = WooCommerceDioClient();
  final systemStatusRepository = SystemStatusRepository(dioClient: dioClient);
  final reportsRepository = ReportsRepository(dioClient: dioClient);
  final productsRepository = ProductsRepository(dioClient: dioClient);
  final ordersRepository = OrdersRepository(dioClient: dioClient);
  final customersRepository = CustomersRepository(dioClient: dioClient);
  final couponsRepository = CouponsRepository(dioClient: dioClient);
  final shippingRepository = ShippingRepository(dioClient: dioClient);
  final taxesRepository = TaxesRepository(dioClient: dioClient);
  final paymentGatewaysRepository =
      PaymentGatewaysRepository(dioClient: dioClient);
  final generalSettingsRepository =
      GeneralSettingsRepository(dioClient: dioClient);
  final productSettingsRepository =
      ProductSettingsRepository(dioClient: dioClient);
  final taxSettingsRepository =
      TaxSettingsRepository(dioClient: dioClient);

  runApp(
    IShineAdminApp(
      systemStatusRepository: systemStatusRepository,
      reportsRepository: reportsRepository,
      productsRepository: productsRepository,
      ordersRepository: ordersRepository,
      customersRepository: customersRepository,
      couponsRepository: couponsRepository,
      shippingRepository: shippingRepository,
      taxesRepository: taxesRepository,
      paymentGatewaysRepository: paymentGatewaysRepository,
      generalSettingsRepository: generalSettingsRepository,
      productSettingsRepository: productSettingsRepository,
      taxSettingsRepository: taxSettingsRepository,
    ),
  );
}

class IShineAdminApp extends StatelessWidget {
  final SystemStatusRepository systemStatusRepository;
  final ReportsRepository reportsRepository;
  final ProductsRepository productsRepository;
  final OrdersRepository? ordersRepository;
  final CustomersRepository? customersRepository;
  final CouponsRepository? couponsRepository;
  final ShippingRepository? shippingRepository;
  final TaxesRepository? taxesRepository;
  final PaymentGatewaysRepository? paymentGatewaysRepository;
  final GeneralSettingsRepository? generalSettingsRepository;
  final ProductSettingsRepository? productSettingsRepository;
  final TaxSettingsRepository? taxSettingsRepository;

  const IShineAdminApp({
    super.key,
    required this.systemStatusRepository,
    required this.reportsRepository,
    required this.productsRepository,
    this.ordersRepository,
    this.customersRepository,
    this.couponsRepository,
    this.shippingRepository,
    this.taxesRepository,
    this.paymentGatewaysRepository,
    this.generalSettingsRepository,
    this.productSettingsRepository,
    this.taxSettingsRepository,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOrdersRepo = ordersRepository ?? OrdersRepository();
    final effectiveCustomersRepo =
        customersRepository ?? CustomersRepository();
    final effectiveCouponsRepo =
        couponsRepository ?? CouponsRepository();
    final effectiveShippingRepo =
        shippingRepository ?? ShippingRepository();
    final effectiveTaxesRepo =
        taxesRepository ?? TaxesRepository();
    final effectivePaymentGatewaysRepo =
        paymentGatewaysRepository ?? PaymentGatewaysRepository();
    final effectiveGeneralSettingsRepo =
        generalSettingsRepository ?? GeneralSettingsRepository();
    final effectiveProductSettingsRepo =
        productSettingsRepository ?? ProductSettingsRepository();
    final effectiveTaxSettingsRepo =
        taxSettingsRepository ?? TaxSettingsRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SystemStatusRepository>.value(
          value: systemStatusRepository,
        ),
        RepositoryProvider<ReportsRepository>.value(value: reportsRepository),
        RepositoryProvider<ProductsRepository>.value(value: productsRepository),
        RepositoryProvider<OrdersRepository>.value(value: effectiveOrdersRepo),
        RepositoryProvider<CustomersRepository>.value(
          value: effectiveCustomersRepo,
        ),
        RepositoryProvider<CouponsRepository>.value(
          value: effectiveCouponsRepo,
        ),
        RepositoryProvider<ShippingRepository>.value(
          value: effectiveShippingRepo,
        ),
        RepositoryProvider<TaxesRepository>.value(
          value: effectiveTaxesRepo,
        ),
        RepositoryProvider<PaymentGatewaysRepository>.value(
          value: effectivePaymentGatewaysRepo,
        ),
        RepositoryProvider<GeneralSettingsRepository>.value(
          value: effectiveGeneralSettingsRepo,
        ),
        RepositoryProvider<ProductSettingsRepository>.value(
          value: effectiveProductSettingsRepo,
        ),
        RepositoryProvider<TaxSettingsRepository>.value(
          value: effectiveTaxSettingsRepo,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(create: (context) => ThemeCubit()),
          BlocProvider<SystemStatusBloc>(
            create: (context) =>
                SystemStatusBloc(repository: systemStatusRepository)
                  ..add(const SystemStatusCheckRequested()),
          ),
          BlocProvider<SalesReportBloc>(
            create: (context) =>
                SalesReportBloc(repository: reportsRepository)
                  ..add(const SalesReportFetchRequested()),
          ),
          BlocProvider<TopSellersBloc>(
            create: (context) =>
                TopSellersBloc(repository: reportsRepository)
                  ..add(const TopSellersFetchRequested()),
          ),
          BlocProvider<ProductsBloc>(
            create: (context) =>
                ProductsBloc(repository: productsRepository)
                  ..add(const ProductsFetchRequested()),
          ),
          BlocProvider<CreateProductBloc>(
            create: (context) =>
                CreateProductBloc(repository: productsRepository),
          ),
          BlocProvider<UpdateProductBloc>(
            create: (context) =>
                UpdateProductBloc(repository: productsRepository),
          ),
          BlocProvider<SingleOrderCubit>(
            create: (context) =>
                SingleOrderCubit(repository: effectiveOrdersRepo),
          ),
          BlocProvider<UpdateOrderCubit>(
            create: (context) =>
                UpdateOrderCubit(repository: effectiveOrdersRepo),
          ),
          BlocProvider<DeleteOrderCubit>(
            create: (context) =>
                DeleteOrderCubit(repository: effectiveOrdersRepo),
          ),
          BlocProvider<CustomersBloc>(
            create: (context) =>
                CustomersBloc(repository: effectiveCustomersRepo)
                  ..add(const CustomersFetchStarted()),
          ),
          BlocProvider<SingleCustomerCubit>(
            create: (context) =>
                SingleCustomerCubit(repository: effectiveCustomersRepo),
          ),
          BlocProvider<UpdateCustomerCubit>(
            create: (context) =>
                UpdateCustomerCubit(repository: effectiveCustomersRepo),
          ),
          BlocProvider<DeleteCustomerCubit>(
            create: (context) =>
                DeleteCustomerCubit(repository: effectiveCustomersRepo),
          ),
          BlocProvider<CouponsBloc>(
            create: (context) =>
                CouponsBloc(repository: effectiveCouponsRepo)
                  ..add(const CouponsFetchStarted()),
          ),
          BlocProvider<CreateCouponCubit>(
            create: (context) =>
                CreateCouponCubit(repository: effectiveCouponsRepo),
          ),
          BlocProvider<UpdateCouponCubit>(
            create: (context) =>
                UpdateCouponCubit(repository: effectiveCouponsRepo),
          ),
          BlocProvider<DeleteCouponCubit>(
            create: (context) =>
                DeleteCouponCubit(repository: effectiveCouponsRepo),
          ),
          BlocProvider<ShippingZonesBloc>(
            create: (context) =>
                ShippingZonesBloc(repository: effectiveShippingRepo)
                  ..add(const ShippingZonesFetchStarted()),
          ),
          BlocProvider<TaxRatesBloc>(
            create: (context) =>
                TaxRatesBloc(repository: effectiveTaxesRepo)
                  ..add(const TaxRatesFetchStarted()),
          ),
          BlocProvider<CreateTaxRateCubit>(
            create: (context) =>
                CreateTaxRateCubit(repository: effectiveTaxesRepo),
          ),
          BlocProvider<PaymentGatewaysBloc>(
            create: (context) =>
                PaymentGatewaysBloc(repository: effectivePaymentGatewaysRepo)
                  ..add(const PaymentGatewaysFetchStarted()),
          ),
          BlocProvider<UpdatePaymentGatewayCubit>(
            create: (context) => UpdatePaymentGatewayCubit(
                repository: effectivePaymentGatewaysRepo),
          ),
          BlocProvider<GeneralSettingsBloc>(
            create: (context) =>
                GeneralSettingsBloc(repository: effectiveGeneralSettingsRepo)
                  ..add(const GeneralSettingsFetchStarted()),
          ),
          BlocProvider<ProductSettingsBloc>(
            create: (context) =>
                ProductSettingsBloc(repository: effectiveProductSettingsRepo)
                  ..add(const ProductSettingsFetchStarted()),
          ),
          BlocProvider<TaxSettingsBloc>(
            create: (context) =>
                TaxSettingsBloc(repository: effectiveTaxSettingsRepo)
                  ..add(const TaxSettingsFetchStarted()),
          ),
          BlocProvider<SystemStatusToolsBloc>(
            create: (context) =>
                SystemStatusToolsBloc(repository: systemStatusRepository)
                  ..add(const SystemStatusToolsFetchStarted()),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              title: 'iShine Control - WooCommerce Admin',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              home: const AdminScaffold(),
            );
          },
        ),
      ),
    );
  }
}
