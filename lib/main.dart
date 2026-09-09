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
import 'features/customers/data/repositories/customers_repository.dart';
import 'features/customers/bloc/single_customer_cubit.dart';
import 'features/coupons/data/repositories/coupons_repository.dart';
import 'features/system_status/bloc/system_status_bloc.dart';
import 'features/system_status/bloc/system_status_event.dart';
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

  runApp(
    IShineAdminApp(
      systemStatusRepository: systemStatusRepository,
      reportsRepository: reportsRepository,
      productsRepository: productsRepository,
      ordersRepository: ordersRepository,
      customersRepository: customersRepository,
      couponsRepository: couponsRepository,
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

  const IShineAdminApp({
    super.key,
    required this.systemStatusRepository,
    required this.reportsRepository,
    required this.productsRepository,
    this.ordersRepository,
    this.customersRepository,
    this.couponsRepository,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOrdersRepo = ordersRepository ?? OrdersRepository();
    final effectiveCustomersRepo =
        customersRepository ?? CustomersRepository();
    final effectiveCouponsRepo =
        couponsRepository ?? CouponsRepository();

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
          BlocProvider<SingleCustomerCubit>(
            create: (context) =>
                SingleCustomerCubit(repository: effectiveCustomersRepo),
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
