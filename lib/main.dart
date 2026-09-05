import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/env_config.dart';
import 'core/network/dio_client.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/layout/presentation/widgets/admin_scaffold.dart';
import 'features/reports/bloc/sales_report_bloc.dart';
import 'features/reports/bloc/sales_report_event.dart';
import 'features/reports/bloc/top_sellers_bloc.dart';
import 'features/reports/bloc/top_sellers_event.dart';
import 'features/reports/data/repositories/reports_repository.dart';
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

  runApp(
    IShineAdminApp(
      systemStatusRepository: systemStatusRepository,
      reportsRepository: reportsRepository,
    ),
  );
}

class IShineAdminApp extends StatelessWidget {
  final SystemStatusRepository systemStatusRepository;
  final ReportsRepository reportsRepository;

  const IShineAdminApp({
    super.key,
    required this.systemStatusRepository,
    required this.reportsRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SystemStatusRepository>.value(
          value: systemStatusRepository,
        ),
        RepositoryProvider<ReportsRepository>.value(value: reportsRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(
            create: (context) => ThemeCubit(),
          ),
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
