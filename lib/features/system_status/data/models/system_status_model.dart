import 'package:equatable/equatable.dart';

/// Root model representing the complete WooCommerce System Status payload
/// from `GET /wp-json/wc/v3/system_status`.
class GETSystemStatusModel {
  Environment? environment;
  Database? database;
  List<ActivePlugins>? activePlugins;
  List<InactivePlugins>? inactivePlugins;
  DropinsMuPlugins? dropinsMuPlugins;
  Theme? theme;
  Settings? settings;
  Security? security;
  List<Pages>? pages;
  List<PostTypeCounts>? postTypeCounts;
  Logging? logging;

  GETSystemStatusModel({
    this.environment,
    this.database,
    this.activePlugins,
    this.inactivePlugins,
    this.dropinsMuPlugins,
    this.theme,
    this.settings,
    this.security,
    this.pages,
    this.postTypeCounts,
    this.logging,
  });

  GETSystemStatusModel.fromJson(Map<String, dynamic> json) {
    environment = json['environment'] != null
        ? Environment.fromJson(json['environment'] as Map<String, dynamic>)
        : null;
    database = json['database'] != null
        ? Database.fromJson(json['database'] as Map<String, dynamic>)
        : null;
    if (json['active_plugins'] != null) {
      activePlugins = <ActivePlugins>[];
      for (final v in (json['active_plugins'] as List)) {
        if (v is Map<String, dynamic>) {
          activePlugins!.add(ActivePlugins.fromJson(v));
        }
      }
    }
    if (json['inactive_plugins'] != null) {
      inactivePlugins = <InactivePlugins>[];
      for (final v in (json['inactive_plugins'] as List)) {
        if (v is Map<String, dynamic>) {
          inactivePlugins!.add(InactivePlugins.fromJson(v));
        }
      }
    }
    dropinsMuPlugins = json['dropins_mu_plugins'] != null
        ? DropinsMuPlugins.fromJson(json['dropins_mu_plugins'] as Map<String, dynamic>)
        : null;
    theme = json['theme'] != null
        ? Theme.fromJson(json['theme'] as Map<String, dynamic>)
        : null;
    settings = json['settings'] != null
        ? Settings.fromJson(json['settings'] as Map<String, dynamic>)
        : null;
    security = json['security'] != null
        ? Security.fromJson(json['security'] as Map<String, dynamic>)
        : null;
    if (json['pages'] != null) {
      pages = <Pages>[];
      for (final v in (json['pages'] as List)) {
        if (v is Map<String, dynamic>) {
          pages!.add(Pages.fromJson(v));
        }
      }
    }
    if (json['post_type_counts'] != null) {
      postTypeCounts = <PostTypeCounts>[];
      for (final v in (json['post_type_counts'] as List)) {
        if (v is Map<String, dynamic>) {
          postTypeCounts!.add(PostTypeCounts.fromJson(v));
        }
      }
    }
    logging = json['logging'] != null
        ? Logging.fromJson(json['logging'] as Map<String, dynamic>)
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (environment != null) {
      data['environment'] = environment!.toJson();
    }
    if (database != null) {
      data['database'] = database!.toJson();
    }
    if (activePlugins != null) {
      data['active_plugins'] = activePlugins!.map((v) => v.toJson()).toList();
    }
    if (inactivePlugins != null) {
      data['inactive_plugins'] =
          inactivePlugins!.map((v) => v.toJson()).toList();
    }
    if (dropinsMuPlugins != null) {
      data['dropins_mu_plugins'] = dropinsMuPlugins!.toJson();
    }
    if (theme != null) {
      data['theme'] = theme!.toJson();
    }
    if (settings != null) {
      data['settings'] = settings!.toJson();
    }
    if (security != null) {
      data['security'] = security!.toJson();
    }
    if (pages != null) {
      data['pages'] = pages!.map((v) => v.toJson()).toList();
    }
    if (postTypeCounts != null) {
      data['post_type_counts'] =
          postTypeCounts!.map((v) => v.toJson()).toList();
    }
    if (logging != null) {
      data['logging'] = logging!.toJson();
    }
    return data;
  }

  /// Convenience adapter converting [GETSystemStatusModel] to the domain entity [SystemStatus].
  SystemStatus toDomain({int responseTimeMs = 0}) {
    return SystemStatus(
      homeUrl: environment?.homeUrl ?? '',
      siteUrl: environment?.siteUrl ?? '',
      wcVersion: environment?.version ?? database?.wcDatabaseVersion ?? 'Unknown',
      wpVersion: environment?.wpVersion ?? 'Unknown',
      phpVersion: environment?.phpVersion ?? 'Unknown',
      serverInfo: environment?.serverInfo ?? 'Unknown',
      mysqlVersion: environment?.mysqlVersionString ?? environment?.mysqlVersion ?? 'Unknown',
      isSecure: security?.secureConnection == true,
      isDebugMode: environment?.wpDebugMode == true,
      currency: settings?.currency ?? 'USD',
      currencySymbol: settings?.currencySymbol ?? '\$',
      activePluginsCount: activePlugins?.length ?? 0,
      themeName: theme?.name ?? 'Default',
      themeVersion: theme?.version ?? '',
      responseTimeMs: responseTimeMs,
      checkedAt: DateTime.now(),
    );
  }
}

class Environment {
  String? homeUrl;
  String? siteUrl;
  String? storeId;
  String? version;
  String? logDirectory;
  bool? logDirectoryWritable;
  String? wpVersion;
  bool? wpMultisite;
  int? wpMemoryLimit;
  bool? wpDebugMode;
  bool? wpCron;
  String? wpEnvironmentType;
  String? language;
  bool? externalObjectCache;
  String? serverInfo;
  String? serverArchitecture;
  String? phpVersion;
  int? phpPostMaxSize;
  int? phpMaxExecutionTime;
  int? phpMaxInputVars;
  String? curlVersion;
  bool? suhosinInstalled;
  int? maxUploadSize;
  String? mysqlVersion;
  String? mysqlVersionString;
  String? defaultTimezone;
  bool? fsockopenOrCurlEnabled;
  bool? soapclientEnabled;
  bool? domdocumentEnabled;
  bool? gzipEnabled;
  bool? mbstringEnabled;
  bool? remotePostSuccessful;
  int? remotePostResponse;
  bool? remoteGetSuccessful;
  int? remoteGetResponse;

  Environment({
    this.homeUrl,
    this.siteUrl,
    this.storeId,
    this.version,
    this.logDirectory,
    this.logDirectoryWritable,
    this.wpVersion,
    this.wpMultisite,
    this.wpMemoryLimit,
    this.wpDebugMode,
    this.wpCron,
    this.wpEnvironmentType,
    this.language,
    this.externalObjectCache,
    this.serverInfo,
    this.serverArchitecture,
    this.phpVersion,
    this.phpPostMaxSize,
    this.phpMaxExecutionTime,
    this.phpMaxInputVars,
    this.curlVersion,
    this.suhosinInstalled,
    this.maxUploadSize,
    this.mysqlVersion,
    this.mysqlVersionString,
    this.defaultTimezone,
    this.fsockopenOrCurlEnabled,
    this.soapclientEnabled,
    this.domdocumentEnabled,
    this.gzipEnabled,
    this.mbstringEnabled,
    this.remotePostSuccessful,
    this.remotePostResponse,
    this.remoteGetSuccessful,
    this.remoteGetResponse,
  });

  Environment.fromJson(Map<String, dynamic> json) {
    homeUrl = json['home_url']?.toString();
    siteUrl = json['site_url']?.toString();
    storeId = json['store_id']?.toString();
    version = json['version']?.toString();
    logDirectory = json['log_directory']?.toString();
    logDirectoryWritable = json['log_directory_writable'] as bool?;
    wpVersion = json['wp_version']?.toString();
    wpMultisite = json['wp_multisite'] as bool?;
    wpMemoryLimit = json['wp_memory_limit'] is num ? (json['wp_memory_limit'] as num).toInt() : null;
    wpDebugMode = json['wp_debug_mode'] as bool?;
    wpCron = json['wp_cron'] as bool?;
    wpEnvironmentType = json['wp_environment_type']?.toString();
    language = json['language']?.toString();
    externalObjectCache = json['external_object_cache'] as bool?;
    serverInfo = json['server_info']?.toString();
    serverArchitecture = json['server_architecture']?.toString();
    phpVersion = json['php_version']?.toString();
    phpPostMaxSize = json['php_post_max_size'] is num ? (json['php_post_max_size'] as num).toInt() : null;
    phpMaxExecutionTime = json['php_max_execution_time'] is num ? (json['php_max_execution_time'] as num).toInt() : null;
    phpMaxInputVars = json['php_max_input_vars'] is num ? (json['php_max_input_vars'] as num).toInt() : null;
    curlVersion = json['curl_version']?.toString();
    suhosinInstalled = json['suhosin_installed'] as bool?;
    maxUploadSize = json['max_upload_size'] is num ? (json['max_upload_size'] as num).toInt() : null;
    mysqlVersion = json['mysql_version']?.toString();
    mysqlVersionString = json['mysql_version_string']?.toString();
    defaultTimezone = json['default_timezone']?.toString();
    fsockopenOrCurlEnabled = json['fsockopen_or_curl_enabled'] as bool?;
    soapclientEnabled = json['soapclient_enabled'] as bool?;
    domdocumentEnabled = json['domdocument_enabled'] as bool?;
    gzipEnabled = json['gzip_enabled'] as bool?;
    mbstringEnabled = json['mbstring_enabled'] as bool?;
    remotePostSuccessful = json['remote_post_successful'] as bool?;
    remotePostResponse = json['remote_post_response'] is num ? (json['remote_post_response'] as num).toInt() : null;
    remoteGetSuccessful = json['remote_get_successful'] as bool?;
    remoteGetResponse = json['remote_get_response'] is num ? (json['remote_get_response'] as num).toInt() : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['home_url'] = homeUrl;
    data['site_url'] = siteUrl;
    data['store_id'] = storeId;
    data['version'] = version;
    data['log_directory'] = logDirectory;
    data['log_directory_writable'] = logDirectoryWritable;
    data['wp_version'] = wpVersion;
    data['wp_multisite'] = wpMultisite;
    data['wp_memory_limit'] = wpMemoryLimit;
    data['wp_debug_mode'] = wpDebugMode;
    data['wp_cron'] = wpCron;
    data['wp_environment_type'] = wpEnvironmentType;
    data['language'] = language;
    data['external_object_cache'] = externalObjectCache;
    data['server_info'] = serverInfo;
    data['server_architecture'] = serverArchitecture;
    data['php_version'] = phpVersion;
    data['php_post_max_size'] = phpPostMaxSize;
    data['php_max_execution_time'] = phpMaxExecutionTime;
    data['php_max_input_vars'] = phpMaxInputVars;
    data['curl_version'] = curlVersion;
    data['suhosin_installed'] = suhosinInstalled;
    data['max_upload_size'] = maxUploadSize;
    data['mysql_version'] = mysqlVersion;
    data['mysql_version_string'] = mysqlVersionString;
    data['default_timezone'] = defaultTimezone;
    data['fsockopen_or_curl_enabled'] = fsockopenOrCurlEnabled;
    data['soapclient_enabled'] = soapclientEnabled;
    data['domdocument_enabled'] = domdocumentEnabled;
    data['gzip_enabled'] = gzipEnabled;
    data['mbstring_enabled'] = mbstringEnabled;
    data['remote_post_successful'] = remotePostSuccessful;
    data['remote_post_response'] = remotePostResponse;
    data['remote_get_successful'] = remoteGetSuccessful;
    data['remote_get_response'] = remoteGetResponse;
    return data;
  }
}

class Database {
  String? wcDatabaseVersion;
  String? databasePrefix;
  String? maxmindGeoipDatabase;
  DatabaseTables? databaseTables;
  DatabaseSize? databaseSize;

  Database({
    this.wcDatabaseVersion,
    this.databasePrefix,
    this.maxmindGeoipDatabase,
    this.databaseTables,
    this.databaseSize,
  });

  Database.fromJson(Map<String, dynamic> json) {
    wcDatabaseVersion = json['wc_database_version']?.toString();
    databasePrefix = json['database_prefix']?.toString();
    maxmindGeoipDatabase = json['maxmind_geoip_database']?.toString();
    databaseTables = json['database_tables'] != null
        ? DatabaseTables.fromJson(json['database_tables'] as Map<String, dynamic>)
        : null;
    databaseSize = json['database_size'] != null
        ? DatabaseSize.fromJson(json['database_size'] as Map<String, dynamic>)
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['wc_database_version'] = wcDatabaseVersion;
    data['database_prefix'] = databasePrefix;
    data['maxmind_geoip_database'] = maxmindGeoipDatabase;
    if (databaseTables != null) {
      data['database_tables'] = databaseTables!.toJson();
    }
    if (databaseSize != null) {
      data['database_size'] = databaseSize!.toJson();
    }
    return data;
  }
}

class DatabaseTables {
  Woocommerce? woocommerce;
  Other? other;

  DatabaseTables({this.woocommerce, this.other});

  DatabaseTables.fromJson(Map<String, dynamic> json) {
    woocommerce = json['woocommerce'] != null
        ? Woocommerce.fromJson(json['woocommerce'] as Map<String, dynamic>)
        : null;
    other = json['other'] != null
        ? Other.fromJson(json['other'] as Map<String, dynamic>)
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (woocommerce != null) {
      data['woocommerce'] = woocommerce!.toJson();
    }
    if (other != null) {
      data['other'] = other!.toJson();
    }
    return data;
  }
}

class Woocommerce {
  WpWoocommerceSessions? wpWoocommerceSessions;
  WpWoocommerceSessions? wpWoocommerceApiKeys;
  WpWoocommerceSessions? wpWoocommerceAttributeTaxonomies;
  WpWoocommerceSessions? wpWoocommerceDownloadableProductPermissions;
  WpWoocommerceSessions? wpWoocommerceOrderItems;
  WpWoocommerceSessions? wpWoocommerceOrderItemmeta;
  WpWoocommerceSessions? wpWoocommerceTaxRates;
  WpWoocommerceSessions? wpWoocommerceTaxRateLocations;
  WpWoocommerceSessions? wpWoocommerceShippingZones;
  WpWoocommerceSessions? wpWoocommerceShippingZoneLocations;
  WpWoocommerceSessions? wpWoocommerceShippingZoneMethods;
  WpWoocommerceSessions? wpWoocommercePaymentTokens;
  WpWoocommerceSessions? wpWoocommercePaymentTokenmeta;
  WpWoocommerceSessions? wpWoocommerceLog;

  Woocommerce({
    this.wpWoocommerceSessions,
    this.wpWoocommerceApiKeys,
    this.wpWoocommerceAttributeTaxonomies,
    this.wpWoocommerceDownloadableProductPermissions,
    this.wpWoocommerceOrderItems,
    this.wpWoocommerceOrderItemmeta,
    this.wpWoocommerceTaxRates,
    this.wpWoocommerceTaxRateLocations,
    this.wpWoocommerceShippingZones,
    this.wpWoocommerceShippingZoneLocations,
    this.wpWoocommerceShippingZoneMethods,
    this.wpWoocommercePaymentTokens,
    this.wpWoocommercePaymentTokenmeta,
    this.wpWoocommerceLog,
  });

  Woocommerce.fromJson(Map<String, dynamic> json) {
    wpWoocommerceSessions = json['wp_woocommerce_sessions'] != null
        ? WpWoocommerceSessions.fromJson(json['wp_woocommerce_sessions'])
        : null;
    wpWoocommerceApiKeys = json['wp_woocommerce_api_keys'] != null
        ? WpWoocommerceSessions.fromJson(json['wp_woocommerce_api_keys'])
        : null;
    wpWoocommerceAttributeTaxonomies =
        json['wp_woocommerce_attribute_taxonomies'] != null
            ? WpWoocommerceSessions.fromJson(
                json['wp_woocommerce_attribute_taxonomies'])
            : null;
    wpWoocommerceDownloadableProductPermissions =
        json['wp_woocommerce_downloadable_product_permissions'] != null
            ? WpWoocommerceSessions.fromJson(
                json['wp_woocommerce_downloadable_product_permissions'])
            : null;
    wpWoocommerceOrderItems = json['wp_woocommerce_order_items'] != null
        ? WpWoocommerceSessions.fromJson(json['wp_woocommerce_order_items'])
        : null;
    wpWoocommerceOrderItemmeta = json['wp_woocommerce_order_itemmeta'] != null
        ? WpWoocommerceSessions.fromJson(json['wp_woocommerce_order_itemmeta'])
        : null;
    wpWoocommerceTaxRates = json['wp_woocommerce_tax_rates'] != null
        ? WpWoocommerceSessions.fromJson(json['wp_woocommerce_tax_rates'])
        : null;
    wpWoocommerceTaxRateLocations =
        json['wp_woocommerce_tax_rate_locations'] != null
            ? WpWoocommerceSessions.fromJson(
                json['wp_woocommerce_tax_rate_locations'])
            : null;
    wpWoocommerceShippingZones = json['wp_woocommerce_shipping_zones'] != null
        ? WpWoocommerceSessions.fromJson(json['wp_woocommerce_shipping_zones'])
        : null;
    wpWoocommerceShippingZoneLocations =
        json['wp_woocommerce_shipping_zone_locations'] != null
            ? WpWoocommerceSessions.fromJson(
                json['wp_woocommerce_shipping_zone_locations'])
            : null;
    wpWoocommerceShippingZoneMethods =
        json['wp_woocommerce_shipping_zone_methods'] != null
            ? WpWoocommerceSessions.fromJson(
                json['wp_woocommerce_shipping_zone_methods'])
            : null;
    wpWoocommercePaymentTokens = json['wp_woocommerce_payment_tokens'] != null
        ? WpWoocommerceSessions.fromJson(json['wp_woocommerce_payment_tokens'])
        : null;
    wpWoocommercePaymentTokenmeta =
        json['wp_woocommerce_payment_tokenmeta'] != null
            ? WpWoocommerceSessions.fromJson(
                json['wp_woocommerce_payment_tokenmeta'])
            : null;
    wpWoocommerceLog = json['wp_woocommerce_log'] != null
        ? WpWoocommerceSessions.fromJson(json['wp_woocommerce_log'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (wpWoocommerceSessions != null) {
      data['wp_woocommerce_sessions'] = wpWoocommerceSessions!.toJson();
    }
    if (wpWoocommerceApiKeys != null) {
      data['wp_woocommerce_api_keys'] = wpWoocommerceApiKeys!.toJson();
    }
    if (wpWoocommerceAttributeTaxonomies != null) {
      data['wp_woocommerce_attribute_taxonomies'] =
          wpWoocommerceAttributeTaxonomies!.toJson();
    }
    if (wpWoocommerceDownloadableProductPermissions != null) {
      data['wp_woocommerce_downloadable_product_permissions'] =
          wpWoocommerceDownloadableProductPermissions!.toJson();
    }
    if (wpWoocommerceOrderItems != null) {
      data['wp_woocommerce_order_items'] =
          wpWoocommerceOrderItems!.toJson();
    }
    if (wpWoocommerceOrderItemmeta != null) {
      data['wp_woocommerce_order_itemmeta'] =
          wpWoocommerceOrderItemmeta!.toJson();
    }
    if (wpWoocommerceTaxRates != null) {
      data['wp_woocommerce_tax_rates'] = wpWoocommerceTaxRates!.toJson();
    }
    if (wpWoocommerceTaxRateLocations != null) {
      data['wp_woocommerce_tax_rate_locations'] =
          wpWoocommerceTaxRateLocations!.toJson();
    }
    if (wpWoocommerceShippingZones != null) {
      data['wp_woocommerce_shipping_zones'] =
          wpWoocommerceShippingZones!.toJson();
    }
    if (wpWoocommerceShippingZoneLocations != null) {
      data['wp_woocommerce_shipping_zone_locations'] =
          wpWoocommerceShippingZoneLocations!.toJson();
    }
    if (wpWoocommerceShippingZoneMethods != null) {
      data['wp_woocommerce_shipping_zone_methods'] =
          wpWoocommerceShippingZoneMethods!.toJson();
    }
    if (wpWoocommercePaymentTokens != null) {
      data['wp_woocommerce_payment_tokens'] =
          wpWoocommercePaymentTokens!.toJson();
    }
    if (wpWoocommercePaymentTokenmeta != null) {
      data['wp_woocommerce_payment_tokenmeta'] =
          wpWoocommercePaymentTokenmeta!.toJson();
    }
    if (wpWoocommerceLog != null) {
      data['wp_woocommerce_log'] = wpWoocommerceLog!.toJson();
    }
    return data;
  }
}

class WpWoocommerceSessions {
  String? data;
  String? index;
  String? engine;

  WpWoocommerceSessions({this.data, this.index, this.engine});

  WpWoocommerceSessions.fromJson(Map<String, dynamic> json) {
    data = json['data']?.toString();
    index = json['index']?.toString();
    engine = json['engine']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['data'] = this.data;
    data['index'] = index;
    data['engine'] = engine;
    return data;
  }
}

class Other {
  WpWoocommerceSessions? wpAcfwStoreCredits;
  WpWoocommerceSessions? wpActionschedulerActions;
  WpWoocommerceSessions? wpActionschedulerClaims;
  WpWoocommerceSessions? wpActionschedulerGroups;
  WpWoocommerceSessions? wpActionschedulerLogs;
  WpWoocommerceSessions? wpBulletinwpOptions;
  WpWoocommerceSessions? wpCevUserLog;
  WpWoocommerceSessions? wpChatyContactFormLeads;
  WpWoocommerceSessions? wpChatyWidgetAnalysis;
  WpWoocommerceSessions? wpCommentmeta;
  WpWoocommerceSessions? wpComments;
  WpWoocommerceSessions? wpCptchAllowlist;
  WpWoocommerceSessions? wpDgwtWcasIndex;
  WpWoocommerceSessions? wpDgwtWcasInvindexCache;
  WpWoocommerceSessions? wpDgwtWcasInvindexDoclist;
  WpWoocommerceSessions? wpDgwtWcasInvindexWordlist;
  WpWoocommerceSessions? wpDgwtWcasStats;
  WpWoocommerceSessions? wpDgwtWcasStorage;
  WpWoocommerceSessions? wpEtAjaxSearchStats;
  WpWoocommerceSessions? wpEEvents;
  WpWoocommerceSessions? wpENotes;
  WpWoocommerceSessions? wpENotesUsersRelations;
  WpWoocommerceSessions? wpESubmissionsActionsLog;
  WpWoocommerceSessions? wpFsmptEmailLogs;
  WpWoocommerceSessions? wpGlaBudgetRecommendations;
  WpWoocommerceSessions? wpGlaShippingRates;
  WpWoocommerceSessions? wpLayerslider;
  WpWoocommerceSessions? wpLayersliderDrafts;
  WpWoocommerceSessions? wpLinks;
  WpWoocommerceSessions? wpLitespeedAvatar;
  WpWoocommerceSessions? wpLitespeedImgOptming;
  WpWoocommerceSessions? wpLitespeedUrl;
  WpWoocommerceSessions? wpLitespeedUrlFile;
  WpWoocommerceSessions? wpOptions;
  WpWoocommerceSessions? wpPostmeta;
  WpWoocommerceSessions? wpPosts;
  WpWoocommerceSessions? wpRankMath404Logs;
  WpWoocommerceSessions? wpRankMathAnalyticsGa;
  WpWoocommerceSessions? wpRankMathAnalyticsGsc;
  WpWoocommerceSessions? wpRankMathAnalyticsInspections;
  WpWoocommerceSessions? wpRankMathAnalyticsKeywordManager;
  WpWoocommerceSessions? wpRankMathAnalyticsObjects;
  WpWoocommerceSessions? wpRankMathInternalLinks;
  WpWoocommerceSessions? wpRankMathInternalMeta;
  WpWoocommerceSessions? wpRankMathLinkGeniusAudit;
  WpWoocommerceSessions? wpRankMathLinkGeniusHistory;
  WpWoocommerceSessions? wpRankMathLinkGeniusMaps;
  WpWoocommerceSessions? wpRankMathLinkGeniusMapVariations;
  WpWoocommerceSessions? wpRankMathLinkGeniusSnapshots;
  WpWoocommerceSessions? wpRankMathRedirections;
  WpWoocommerceSessions? wpRankMathRedirectionsCache;
  WpWoocommerceSessions? wpRevsliderCss;
  WpWoocommerceSessions? wpRevsliderCssBkp;
  WpWoocommerceSessions? wpRevsliderLayerAnimations;
  WpWoocommerceSessions? wpRevsliderLayerAnimationsBkp;
  WpWoocommerceSessions? wpRevsliderNavigations;
  WpWoocommerceSessions? wpRevsliderNavigationsBkp;
  WpWoocommerceSessions? wpRevsliderSliders;
  WpWoocommerceSessions? wpRevsliderSliders7;
  WpWoocommerceSessions? wpRevsliderSlidersBkp;
  WpWoocommerceSessions? wpRevsliderSlides;
  WpWoocommerceSessions? wpRevsliderSlides7;
  WpWoocommerceSessions? wpRevsliderSlidesBkp;
  WpWoocommerceSessions? wpRevsliderStaticSlides;
  WpWoocommerceSessions? wpRevsliderStaticSlidesBkp;
  WpWoocommerceSessions? wpSmTasks;
  WpWoocommerceSessions? wpTermmeta;
  WpWoocommerceSessions? wpTerms;
  WpWoocommerceSessions? wpTermRelationships;
  WpWoocommerceSessions? wpTermTaxonomy;
  WpWoocommerceSessions? wpUsermeta;
  WpWoocommerceSessions? wpUsers;
  WpWoocommerceSessions? wpWcAdminNotes;
  WpWoocommerceSessions? wpWcAdminNoteActions;
  WpWoocommerceSessions? wpWcCategoryLookup;
  WpWoocommerceSessions? wpWcCustomerLookup;
  WpWoocommerceSessions? wpWcDownloadLog;
  WpWoocommerceSessions? wpWcOrders;
  WpWoocommerceSessions? wpWcOrdersMeta;
  WpWoocommerceSessions? wpWcOrderAddresses;
  WpWoocommerceSessions? wpWcOrderCouponLookup;
  WpWoocommerceSessions? wpWcOrderOperationalData;
  WpWoocommerceSessions? wpWcOrderProductLookup;
  WpWoocommerceSessions? wpWcOrderStats;
  WpWoocommerceSessions? wpWcOrderTaxLookup;
  WpWoocommerceSessions? wpWcProductAttributesLookup;
  WpWoocommerceSessions? wpWcProductDownloadDirectories;
  WpWoocommerceSessions? wpWcProductMetaLookup;
  WpWoocommerceSessions? wpWcRateLimits;
  WpWoocommerceSessions? wpWcReservedStock;
  WpWoocommerceSessions? wpWcScOrderCouponMetaLookup;
  WpWoocommerceSessions? wpWcSmartCoupons;
  WpWoocommerceSessions? wpWcTaxRateClasses;
  WpWoocommerceSessions? wpWcWebhooks;
  WpWoocommerceSessions? wpWoocommerceExportedCsvItems;
  WpWoocommerceSessions? wpWoodmartUnsubscribedEmails;
  WpWoocommerceSessions? wpWoodmartWishlists;
  WpWoocommerceSessions? wpWoodmartWishlistProducts;
  WpWoocommerceSessions? wpWoolentorAbandonedCart;
  WpWoocommerceSessions? wpWoolentorAbandonedCartEmailLogs;
  WpWoocommerceSessions? wpWoolentorAbandonedCartEmailTemplates;
  WpWoocommerceSessions? wpWoosSearchAnalytics;
  WpWoocommerceSessions? wpWoosSearchData;
  WpWoocommerceSessions? wpWpformsEntries;
  WpWoocommerceSessions? wpWpformsEntryFields;
  WpWoocommerceSessions? wpWpformsEntryMeta;
  WpWoocommerceSessions? wpWpsHit;
  WpWoocommerceSessions? wpWpsIndex;
  WpWoocommerceSessions? wpWpsKey;
  WpWoocommerceSessions? wpWpsObjectTerm;
  WpWoocommerceSessions? wpWpsObjectType;
  WpWoocommerceSessions? wpWpsQuery;
  WpWoocommerceSessions? wpWpsUri;
  WpWoocommerceSessions? wpWpsUserAgent;
  WpWoocommerceSessions? wpWwsAnalytics;
  WpWoocommerceSessions? wpYithWcwl;
  WpWoocommerceSessions? wpYithWcwlItemmeta;
  WpWoocommerceSessions? wpYithWcwlLists;

  Other({
    this.wpAcfwStoreCredits,
    this.wpActionschedulerActions,
    this.wpActionschedulerClaims,
    this.wpActionschedulerGroups,
    this.wpActionschedulerLogs,
    this.wpBulletinwpOptions,
    this.wpCevUserLog,
    this.wpChatyContactFormLeads,
    this.wpChatyWidgetAnalysis,
    this.wpCommentmeta,
    this.wpComments,
    this.wpCptchAllowlist,
    this.wpDgwtWcasIndex,
    this.wpDgwtWcasInvindexCache,
    this.wpDgwtWcasInvindexDoclist,
    this.wpDgwtWcasInvindexWordlist,
    this.wpDgwtWcasStats,
    this.wpDgwtWcasStorage,
    this.wpEtAjaxSearchStats,
    this.wpEEvents,
    this.wpENotes,
    this.wpENotesUsersRelations,
    this.wpESubmissionsActionsLog,
    this.wpFsmptEmailLogs,
    this.wpGlaBudgetRecommendations,
    this.wpGlaShippingRates,
    this.wpLayerslider,
    this.wpLayersliderDrafts,
    this.wpLinks,
    this.wpLitespeedAvatar,
    this.wpLitespeedImgOptming,
    this.wpLitespeedUrl,
    this.wpLitespeedUrlFile,
    this.wpOptions,
    this.wpPostmeta,
    this.wpPosts,
    this.wpRankMath404Logs,
    this.wpRankMathAnalyticsGa,
    this.wpRankMathAnalyticsGsc,
    this.wpRankMathAnalyticsInspections,
    this.wpRankMathAnalyticsKeywordManager,
    this.wpRankMathAnalyticsObjects,
    this.wpRankMathInternalLinks,
    this.wpRankMathInternalMeta,
    this.wpRankMathLinkGeniusAudit,
    this.wpRankMathLinkGeniusHistory,
    this.wpRankMathLinkGeniusMaps,
    this.wpRankMathLinkGeniusMapVariations,
    this.wpRankMathLinkGeniusSnapshots,
    this.wpRankMathRedirections,
    this.wpRankMathRedirectionsCache,
    this.wpRevsliderCss,
    this.wpRevsliderCssBkp,
    this.wpRevsliderLayerAnimations,
    this.wpRevsliderLayerAnimationsBkp,
    this.wpRevsliderNavigations,
    this.wpRevsliderNavigationsBkp,
    this.wpRevsliderSliders,
    this.wpRevsliderSliders7,
    this.wpRevsliderSlidersBkp,
    this.wpRevsliderSlides,
    this.wpRevsliderSlides7,
    this.wpRevsliderSlidesBkp,
    this.wpRevsliderStaticSlides,
    this.wpRevsliderStaticSlidesBkp,
    this.wpSmTasks,
    this.wpTermmeta,
    this.wpTerms,
    this.wpTermRelationships,
    this.wpTermTaxonomy,
    this.wpUsermeta,
    this.wpUsers,
    this.wpWcAdminNotes,
    this.wpWcAdminNoteActions,
    this.wpWcCategoryLookup,
    this.wpWcCustomerLookup,
    this.wpWcDownloadLog,
    this.wpWcOrders,
    this.wpWcOrdersMeta,
    this.wpWcOrderAddresses,
    this.wpWcOrderCouponLookup,
    this.wpWcOrderOperationalData,
    this.wpWcOrderProductLookup,
    this.wpWcOrderStats,
    this.wpWcOrderTaxLookup,
    this.wpWcProductAttributesLookup,
    this.wpWcProductDownloadDirectories,
    this.wpWcProductMetaLookup,
    this.wpWcRateLimits,
    this.wpWcReservedStock,
    this.wpWcScOrderCouponMetaLookup,
    this.wpWcSmartCoupons,
    this.wpWcTaxRateClasses,
    this.wpWcWebhooks,
    this.wpWoocommerceExportedCsvItems,
    this.wpWoodmartUnsubscribedEmails,
    this.wpWoodmartWishlists,
    this.wpWoodmartWishlistProducts,
    this.wpWoolentorAbandonedCart,
    this.wpWoolentorAbandonedCartEmailLogs,
    this.wpWoolentorAbandonedCartEmailTemplates,
    this.wpWoosSearchAnalytics,
    this.wpWoosSearchData,
    this.wpWpformsEntries,
    this.wpWpformsEntryFields,
    this.wpWpformsEntryMeta,
    this.wpWpsHit,
    this.wpWpsIndex,
    this.wpWpsKey,
    this.wpWpsObjectTerm,
    this.wpWpsObjectType,
    this.wpWpsQuery,
    this.wpWpsUri,
    this.wpWpsUserAgent,
    this.wpWwsAnalytics,
    this.wpYithWcwl,
    this.wpYithWcwlItemmeta,
    this.wpYithWcwlLists,
  });

  Other.fromJson(Map<String, dynamic> json) {
    wpAcfwStoreCredits = _parseSession(json['wp_acfw_store_credits']);
    wpActionschedulerActions = _parseSession(json['wp_actionscheduler_actions']);
    wpActionschedulerClaims = _parseSession(json['wp_actionscheduler_claims']);
    wpActionschedulerGroups = _parseSession(json['wp_actionscheduler_groups']);
    wpActionschedulerLogs = _parseSession(json['wp_actionscheduler_logs']);
    wpBulletinwpOptions = _parseSession(json['wp_bulletinwp_options']);
    wpCevUserLog = _parseSession(json['wp_cev_user_log']);
    wpChatyContactFormLeads = _parseSession(json['wp_chaty_contact_form_leads']);
    wpChatyWidgetAnalysis = _parseSession(json['wp_chaty_widget_analysis']);
    wpCommentmeta = _parseSession(json['wp_commentmeta']);
    wpComments = _parseSession(json['wp_comments']);
    wpCptchAllowlist = _parseSession(json['wp_cptch_allowlist']);
    wpDgwtWcasIndex = _parseSession(json['wp_dgwt_wcas_index']);
    wpDgwtWcasInvindexCache = _parseSession(json['wp_dgwt_wcas_invindex_cache']);
    wpDgwtWcasInvindexDoclist = _parseSession(json['wp_dgwt_wcas_invindex_doclist']);
    wpDgwtWcasInvindexWordlist = _parseSession(json['wp_dgwt_wcas_invindex_wordlist']);
    wpDgwtWcasStats = _parseSession(json['wp_dgwt_wcas_stats']);
    wpDgwtWcasStorage = _parseSession(json['wp_dgwt_wcas_storage']);
    wpEtAjaxSearchStats = _parseSession(json['wp_et_ajax_search_stats']);
    wpEEvents = _parseSession(json['wp_e_events']);
    wpENotes = _parseSession(json['wp_e_notes']);
    wpENotesUsersRelations = _parseSession(json['wp_e_notes_users_relations']);
    wpESubmissionsActionsLog = _parseSession(json['wp_e_submissions_actions_log']);
    wpFsmptEmailLogs = _parseSession(json['wp_fsmpt_email_logs']);
    wpGlaBudgetRecommendations = _parseSession(json['wp_gla_budget_recommendations']);
    wpGlaShippingRates = _parseSession(json['wp_gla_shipping_rates']);
    wpLayerslider = _parseSession(json['wp_layerslider']);
    wpLayersliderDrafts = _parseSession(json['wp_layerslider_drafts']);
    wpLinks = _parseSession(json['wp_links']);
    wpLitespeedAvatar = _parseSession(json['wp_litespeed_avatar']);
    wpLitespeedImgOptming = _parseSession(json['wp_litespeed_img_optming']);
    wpLitespeedUrl = _parseSession(json['wp_litespeed_url']);
    wpLitespeedUrlFile = _parseSession(json['wp_litespeed_url_file']);
    wpOptions = _parseSession(json['wp_options']);
    wpPostmeta = _parseSession(json['wp_postmeta']);
    wpPosts = _parseSession(json['wp_posts']);
    wpRankMath404Logs = _parseSession(json['wp_rank_math_404_logs']);
    wpRankMathAnalyticsGa = _parseSession(json['wp_rank_math_analytics_ga']);
    wpRankMathAnalyticsGsc = _parseSession(json['wp_rank_math_analytics_gsc']);
    wpRankMathAnalyticsInspections = _parseSession(json['wp_rank_math_analytics_inspections']);
    wpRankMathAnalyticsKeywordManager = _parseSession(json['wp_rank_math_analytics_keyword_manager']);
    wpRankMathAnalyticsObjects = _parseSession(json['wp_rank_math_analytics_objects']);
    wpRankMathInternalLinks = _parseSession(json['wp_rank_math_internal_links']);
    wpRankMathInternalMeta = _parseSession(json['wp_rank_math_internal_meta']);
    wpRankMathLinkGeniusAudit = _parseSession(json['wp_rank_math_link_genius_audit']);
    wpRankMathLinkGeniusHistory = _parseSession(json['wp_rank_math_link_genius_history']);
    wpRankMathLinkGeniusMaps = _parseSession(json['wp_rank_math_link_genius_maps']);
    wpRankMathLinkGeniusMapVariations = _parseSession(json['wp_rank_math_link_genius_map_variations']);
    wpRankMathLinkGeniusSnapshots = _parseSession(json['wp_rank_math_link_genius_snapshots']);
    wpRankMathRedirections = _parseSession(json['wp_rank_math_redirections']);
    wpRankMathRedirectionsCache = _parseSession(json['wp_rank_math_redirections_cache']);
    wpRevsliderCss = _parseSession(json['wp_revslider_css']);
    wpRevsliderCssBkp = _parseSession(json['wp_revslider_css_bkp']);
    wpRevsliderLayerAnimations = _parseSession(json['wp_revslider_layer_animations']);
    wpRevsliderLayerAnimationsBkp = _parseSession(json['wp_revslider_layer_animations_bkp']);
    wpRevsliderNavigations = _parseSession(json['wp_revslider_navigations']);
    wpRevsliderNavigationsBkp = _parseSession(json['wp_revslider_navigations_bkp']);
    wpRevsliderSliders = _parseSession(json['wp_revslider_sliders']);
    wpRevsliderSliders7 = _parseSession(json['wp_revslider_sliders7']);
    wpRevsliderSlidersBkp = _parseSession(json['wp_revslider_sliders_bkp']);
    wpRevsliderSlides = _parseSession(json['wp_revslider_slides']);
    wpRevsliderSlides7 = _parseSession(json['wp_revslider_slides7']);
    wpRevsliderSlidesBkp = _parseSession(json['wp_revslider_slides_bkp']);
    wpRevsliderStaticSlides = _parseSession(json['wp_revslider_static_slides']);
    wpRevsliderStaticSlidesBkp = _parseSession(json['wp_revslider_static_slides_bkp']);
    wpSmTasks = _parseSession(json['wp_sm_tasks']);
    wpTermmeta = _parseSession(json['wp_termmeta']);
    wpTerms = _parseSession(json['wp_terms']);
    wpTermRelationships = _parseSession(json['wp_term_relationships']);
    wpTermTaxonomy = _parseSession(json['wp_term_taxonomy']);
    wpUsermeta = _parseSession(json['wp_usermeta']);
    wpUsers = _parseSession(json['wp_users']);
    wpWcAdminNotes = _parseSession(json['wp_wc_admin_notes']);
    wpWcAdminNoteActions = _parseSession(json['wp_wc_admin_note_actions']);
    wpWcCategoryLookup = _parseSession(json['wp_wc_category_lookup']);
    wpWcCustomerLookup = _parseSession(json['wp_wc_customer_lookup']);
    wpWcDownloadLog = _parseSession(json['wp_wc_download_log']);
    wpWcOrders = _parseSession(json['wp_wc_orders']);
    wpWcOrdersMeta = _parseSession(json['wp_wc_orders_meta']);
    wpWcOrderAddresses = _parseSession(json['wp_wc_order_addresses']);
    wpWcOrderCouponLookup = _parseSession(json['wp_wc_order_coupon_lookup']);
    wpWcOrderOperationalData = _parseSession(json['wp_wc_order_operational_data']);
    wpWcOrderProductLookup = _parseSession(json['wp_wc_order_product_lookup']);
    wpWcOrderStats = _parseSession(json['wp_wc_order_stats']);
    wpWcOrderTaxLookup = _parseSession(json['wp_wc_order_tax_lookup']);
    wpWcProductAttributesLookup = _parseSession(json['wp_wc_product_attributes_lookup']);
    wpWcProductDownloadDirectories = _parseSession(json['wp_wc_product_download_directories']);
    wpWcProductMetaLookup = _parseSession(json['wp_wc_product_meta_lookup']);
    wpWcRateLimits = _parseSession(json['wp_wc_rate_limits']);
    wpWcReservedStock = _parseSession(json['wp_wc_reserved_stock']);
    wpWcScOrderCouponMetaLookup = _parseSession(json['wp_wc_sc_order_coupon_meta_lookup']);
    wpWcSmartCoupons = _parseSession(json['wp_wc_smart_coupons']);
    wpWcTaxRateClasses = _parseSession(json['wp_wc_tax_rate_classes']);
    wpWcWebhooks = _parseSession(json['wp_wc_webhooks']);
    wpWoocommerceExportedCsvItems = _parseSession(json['wp_woocommerce_exported_csv_items']);
    wpWoodmartUnsubscribedEmails = _parseSession(json['wp_woodmart_unsubscribed_emails']);
    wpWoodmartWishlists = _parseSession(json['wp_woodmart_wishlists']);
    wpWoodmartWishlistProducts = _parseSession(json['wp_woodmart_wishlist_products']);
    wpWoolentorAbandonedCart = _parseSession(json['wp_woolentor_abandoned_cart']);
    wpWoolentorAbandonedCartEmailLogs = _parseSession(json['wp_woolentor_abandoned_cart_email_logs']);
    wpWoolentorAbandonedCartEmailTemplates = _parseSession(json['wp_woolentor_abandoned_cart_email_templates']);
    wpWoosSearchAnalytics = _parseSession(json['wp_woos_search_analytics']);
    wpWoosSearchData = _parseSession(json['wp_woos_search_data']);
    wpWpformsEntries = _parseSession(json['wp_wpforms_entries']);
    wpWpformsEntryFields = _parseSession(json['wp_wpforms_entry_fields']);
    wpWpformsEntryMeta = _parseSession(json['wp_wpforms_entry_meta']);
    wpWpsHit = _parseSession(json['wp_wps_hit']);
    wpWpsIndex = _parseSession(json['wp_wps_index']);
    wpWpsKey = _parseSession(json['wp_wps_key']);
    wpWpsObjectTerm = _parseSession(json['wp_wps_object_term']);
    wpWpsObjectType = _parseSession(json['wp_wps_object_type']);
    wpWpsQuery = _parseSession(json['wp_wps_query']);
    wpWpsUri = _parseSession(json['wp_wps_uri']);
    wpWpsUserAgent = _parseSession(json['wp_wps_user_agent']);
    wpWwsAnalytics = _parseSession(json['wp_wws_analytics']);
    wpYithWcwl = _parseSession(json['wp_yith_wcwl']);
    wpYithWcwlItemmeta = _parseSession(json['wp_yith_wcwl_itemmeta']);
    wpYithWcwlLists = _parseSession(json['wp_yith_wcwl_lists']);
  }

  static WpWoocommerceSessions? _parseSession(dynamic json) {
    if (json is Map<String, dynamic>) {
      return WpWoocommerceSessions.fromJson(json);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (wpAcfwStoreCredits != null) data['wp_acfw_store_credits'] = wpAcfwStoreCredits!.toJson();
    if (wpActionschedulerActions != null) data['wp_actionscheduler_actions'] = wpActionschedulerActions!.toJson();
    if (wpActionschedulerClaims != null) data['wp_actionscheduler_claims'] = wpActionschedulerClaims!.toJson();
    if (wpActionschedulerGroups != null) data['wp_actionscheduler_groups'] = wpActionschedulerGroups!.toJson();
    if (wpActionschedulerLogs != null) data['wp_actionscheduler_logs'] = wpActionschedulerLogs!.toJson();
    if (wpBulletinwpOptions != null) data['wp_bulletinwp_options'] = wpBulletinwpOptions!.toJson();
    if (wpCevUserLog != null) data['wp_cev_user_log'] = wpCevUserLog!.toJson();
    if (wpChatyContactFormLeads != null) data['wp_chaty_contact_form_leads'] = wpChatyContactFormLeads!.toJson();
    if (wpChatyWidgetAnalysis != null) data['wp_chaty_widget_analysis'] = wpChatyWidgetAnalysis!.toJson();
    if (wpCommentmeta != null) data['wp_commentmeta'] = wpCommentmeta!.toJson();
    if (wpComments != null) data['wp_comments'] = wpComments!.toJson();
    if (wpCptchAllowlist != null) data['wp_cptch_allowlist'] = wpCptchAllowlist!.toJson();
    if (wpDgwtWcasIndex != null) data['wp_dgwt_wcas_index'] = wpDgwtWcasIndex!.toJson();
    if (wpDgwtWcasInvindexCache != null) data['wp_dgwt_wcas_invindex_cache'] = wpDgwtWcasInvindexCache!.toJson();
    if (wpDgwtWcasInvindexDoclist != null) data['wp_dgwt_wcas_invindex_doclist'] = wpDgwtWcasInvindexDoclist!.toJson();
    if (wpDgwtWcasInvindexWordlist != null) data['wp_dgwt_wcas_invindex_wordlist'] = wpDgwtWcasInvindexWordlist!.toJson();
    if (wpDgwtWcasStats != null) data['wp_dgwt_wcas_stats'] = wpDgwtWcasStats!.toJson();
    if (wpDgwtWcasStorage != null) data['wp_dgwt_wcas_storage'] = wpDgwtWcasStorage!.toJson();
    if (wpEtAjaxSearchStats != null) data['wp_et_ajax_search_stats'] = wpEtAjaxSearchStats!.toJson();
    if (wpEEvents != null) data['wp_e_events'] = wpEEvents!.toJson();
    if (wpENotes != null) data['wp_e_notes'] = wpENotes!.toJson();
    if (wpENotesUsersRelations != null) data['wp_e_notes_users_relations'] = wpENotesUsersRelations!.toJson();
    if (wpESubmissionsActionsLog != null) data['wp_e_submissions_actions_log'] = wpESubmissionsActionsLog!.toJson();
    if (wpFsmptEmailLogs != null) data['wp_fsmpt_email_logs'] = wpFsmptEmailLogs!.toJson();
    if (wpGlaBudgetRecommendations != null) data['wp_gla_budget_recommendations'] = wpGlaBudgetRecommendations!.toJson();
    if (wpGlaShippingRates != null) data['wp_gla_shipping_rates'] = wpGlaShippingRates!.toJson();
    if (wpLayerslider != null) data['wp_layerslider'] = wpLayerslider!.toJson();
    if (wpLayersliderDrafts != null) data['wp_layerslider_drafts'] = wpLayersliderDrafts!.toJson();
    if (wpLinks != null) data['wp_links'] = wpLinks!.toJson();
    if (wpLitespeedAvatar != null) data['wp_litespeed_avatar'] = wpLitespeedAvatar!.toJson();
    if (wpLitespeedImgOptming != null) data['wp_litespeed_img_optming'] = wpLitespeedImgOptming!.toJson();
    if (wpLitespeedUrl != null) data['wp_litespeed_url'] = wpLitespeedUrl!.toJson();
    if (wpLitespeedUrlFile != null) data['wp_litespeed_url_file'] = wpLitespeedUrlFile!.toJson();
    if (wpOptions != null) data['wp_options'] = wpOptions!.toJson();
    if (wpPostmeta != null) data['wp_postmeta'] = wpPostmeta!.toJson();
    if (wpPosts != null) data['wp_posts'] = wpPosts!.toJson();
    if (wpRankMath404Logs != null) data['wp_rank_math_404_logs'] = wpRankMath404Logs!.toJson();
    if (wpRankMathAnalyticsGa != null) data['wp_rank_math_analytics_ga'] = wpRankMathAnalyticsGa!.toJson();
    if (wpRankMathAnalyticsGsc != null) data['wp_rank_math_analytics_gsc'] = wpRankMathAnalyticsGsc!.toJson();
    if (wpRankMathAnalyticsInspections != null) data['wp_rank_math_analytics_inspections'] = wpRankMathAnalyticsInspections!.toJson();
    if (wpRankMathAnalyticsKeywordManager != null) data['wp_rank_math_analytics_keyword_manager'] = wpRankMathAnalyticsKeywordManager!.toJson();
    if (wpRankMathAnalyticsObjects != null) data['wp_rank_math_analytics_objects'] = wpRankMathAnalyticsObjects!.toJson();
    if (wpRankMathInternalLinks != null) data['wp_rank_math_internal_links'] = wpRankMathInternalLinks!.toJson();
    if (wpRankMathInternalMeta != null) data['wp_rank_math_internal_meta'] = wpRankMathInternalMeta!.toJson();
    if (wpRankMathLinkGeniusAudit != null) data['wp_rank_math_link_genius_audit'] = wpRankMathLinkGeniusAudit!.toJson();
    if (wpRankMathLinkGeniusHistory != null) data['wp_rank_math_link_genius_history'] = wpRankMathLinkGeniusHistory!.toJson();
    if (wpRankMathLinkGeniusMaps != null) data['wp_rank_math_link_genius_maps'] = wpRankMathLinkGeniusMaps!.toJson();
    if (wpRankMathLinkGeniusMapVariations != null) data['wp_rank_math_link_genius_map_variations'] = wpRankMathLinkGeniusMapVariations!.toJson();
    if (wpRankMathLinkGeniusSnapshots != null) data['wp_rank_math_link_genius_snapshots'] = wpRankMathLinkGeniusSnapshots!.toJson();
    if (wpRankMathRedirections != null) data['wp_rank_math_redirections'] = wpRankMathRedirections!.toJson();
    if (wpRankMathRedirectionsCache != null) data['wp_rank_math_redirections_cache'] = wpRankMathRedirectionsCache!.toJson();
    if (wpRevsliderCss != null) data['wp_revslider_css'] = wpRevsliderCss!.toJson();
    if (wpRevsliderCssBkp != null) data['wp_revslider_css_bkp'] = wpRevsliderCssBkp!.toJson();
    if (wpRevsliderLayerAnimations != null) data['wp_revslider_layer_animations'] = wpRevsliderLayerAnimations!.toJson();
    if (wpRevsliderLayerAnimationsBkp != null) data['wp_revslider_layer_animations_bkp'] = wpRevsliderLayerAnimationsBkp!.toJson();
    if (wpRevsliderNavigations != null) data['wp_revslider_navigations'] = wpRevsliderNavigations!.toJson();
    if (wpRevsliderNavigationsBkp != null) data['wp_revslider_navigations_bkp'] = wpRevsliderNavigationsBkp!.toJson();
    if (wpRevsliderSliders != null) data['wp_revslider_sliders'] = wpRevsliderSliders!.toJson();
    if (wpRevsliderSliders7 != null) data['wp_revslider_sliders7'] = wpRevsliderSliders7!.toJson();
    if (wpRevsliderSlidersBkp != null) data['wp_revslider_sliders_bkp'] = wpRevsliderSlidersBkp!.toJson();
    if (wpRevsliderSlides != null) data['wp_revslider_slides'] = wpRevsliderSlides!.toJson();
    if (wpRevsliderSlides7 != null) data['wp_revslider_slides7'] = wpRevsliderSlides7!.toJson();
    if (wpRevsliderSlidesBkp != null) data['wp_revslider_slides_bkp'] = wpRevsliderSlidesBkp!.toJson();
    if (wpRevsliderStaticSlides != null) data['wp_revslider_static_slides'] = wpRevsliderStaticSlides!.toJson();
    if (wpRevsliderStaticSlidesBkp != null) data['wp_revslider_static_slides_bkp'] = wpRevsliderStaticSlidesBkp!.toJson();
    if (wpSmTasks != null) data['wp_sm_tasks'] = wpSmTasks!.toJson();
    if (wpTermmeta != null) data['wp_termmeta'] = wpTermmeta!.toJson();
    if (wpTerms != null) data['wp_terms'] = wpTerms!.toJson();
    if (wpTermRelationships != null) data['wp_term_relationships'] = wpTermRelationships!.toJson();
    if (wpTermTaxonomy != null) data['wp_term_taxonomy'] = wpTermTaxonomy!.toJson();
    if (wpUsermeta != null) data['wp_usermeta'] = wpUsermeta!.toJson();
    if (wpUsers != null) data['wp_users'] = wpUsers!.toJson();
    if (wpWcAdminNotes != null) data['wp_wc_admin_notes'] = wpWcAdminNotes!.toJson();
    if (wpWcAdminNoteActions != null) data['wp_wc_admin_note_actions'] = wpWcAdminNoteActions!.toJson();
    if (wpWcCategoryLookup != null) data['wp_wc_category_lookup'] = wpWcCategoryLookup!.toJson();
    if (wpWcCustomerLookup != null) data['wp_wc_customer_lookup'] = wpWcCustomerLookup!.toJson();
    if (wpWcDownloadLog != null) data['wp_wc_download_log'] = wpWcDownloadLog!.toJson();
    if (wpWcOrders != null) data['wp_wc_orders'] = wpWcOrders!.toJson();
    if (wpWcOrdersMeta != null) data['wp_wc_orders_meta'] = wpWcOrdersMeta!.toJson();
    if (wpWcOrderAddresses != null) data['wp_wc_order_addresses'] = wpWcOrderAddresses!.toJson();
    if (wpWcOrderCouponLookup != null) data['wp_wc_order_coupon_lookup'] = wpWcOrderCouponLookup!.toJson();
    if (wpWcOrderOperationalData != null) data['wp_wc_order_operational_data'] = wpWcOrderOperationalData!.toJson();
    if (wpWcOrderProductLookup != null) data['wp_wc_order_product_lookup'] = wpWcOrderProductLookup!.toJson();
    if (wpWcOrderStats != null) data['wp_wc_order_stats'] = wpWcOrderStats!.toJson();
    if (wpWcOrderTaxLookup != null) data['wp_wc_order_tax_lookup'] = wpWcOrderTaxLookup!.toJson();
    if (wpWcProductAttributesLookup != null) data['wp_wc_product_attributes_lookup'] = wpWcProductAttributesLookup!.toJson();
    if (wpWcProductDownloadDirectories != null) data['wp_wc_product_download_directories'] = wpWcProductDownloadDirectories!.toJson();
    if (wpWcProductMetaLookup != null) data['wp_wc_product_meta_lookup'] = wpWcProductMetaLookup!.toJson();
    if (wpWcRateLimits != null) data['wp_wc_rate_limits'] = wpWcRateLimits!.toJson();
    if (wpWcReservedStock != null) data['wp_wc_reserved_stock'] = wpWcReservedStock!.toJson();
    if (wpWcScOrderCouponMetaLookup != null) data['wp_wc_sc_order_coupon_meta_lookup'] = wpWcScOrderCouponMetaLookup!.toJson();
    if (wpWcSmartCoupons != null) data['wp_wc_smart_coupons'] = wpWcSmartCoupons!.toJson();
    if (wpWcTaxRateClasses != null) data['wp_wc_tax_rate_classes'] = wpWcTaxRateClasses!.toJson();
    if (wpWcWebhooks != null) data['wp_wc_webhooks'] = wpWcWebhooks!.toJson();
    if (wpWoocommerceExportedCsvItems != null) data['wp_woocommerce_exported_csv_items'] = wpWoocommerceExportedCsvItems!.toJson();
    if (wpWoodmartUnsubscribedEmails != null) data['wp_woodmart_unsubscribed_emails'] = wpWoodmartUnsubscribedEmails!.toJson();
    if (wpWoodmartWishlists != null) data['wp_woodmart_wishlists'] = wpWoodmartWishlists!.toJson();
    if (wpWoodmartWishlistProducts != null) data['wp_woodmart_wishlist_products'] = wpWoodmartWishlistProducts!.toJson();
    if (wpWoolentorAbandonedCart != null) data['wp_woolentor_abandoned_cart'] = wpWoolentorAbandonedCart!.toJson();
    if (wpWoolentorAbandonedCartEmailLogs != null) data['wp_woolentor_abandoned_cart_email_logs'] = wpWoolentorAbandonedCartEmailLogs!.toJson();
    if (wpWoolentorAbandonedCartEmailTemplates != null) data['wp_woolentor_abandoned_cart_email_templates'] = wpWoolentorAbandonedCartEmailTemplates!.toJson();
    if (wpWoosSearchAnalytics != null) data['wp_woos_search_analytics'] = wpWoosSearchAnalytics!.toJson();
    if (wpWoosSearchData != null) data['wp_woos_search_data'] = wpWoosSearchData!.toJson();
    if (wpWpformsEntries != null) data['wp_wpforms_entries'] = wpWpformsEntries!.toJson();
    if (wpWpformsEntryFields != null) data['wp_wpforms_entry_fields'] = wpWpformsEntryFields!.toJson();
    if (wpWpformsEntryMeta != null) data['wp_wpforms_entry_meta'] = wpWpformsEntryMeta!.toJson();
    if (wpWpsHit != null) data['wp_wps_hit'] = wpWpsHit!.toJson();
    if (wpWpsIndex != null) data['wp_wps_index'] = wpWpsIndex!.toJson();
    if (wpWpsKey != null) data['wp_wps_key'] = wpWpsKey!.toJson();
    if (wpWpsObjectTerm != null) data['wp_wps_object_term'] = wpWpsObjectTerm!.toJson();
    if (wpWpsObjectType != null) data['wp_wps_object_type'] = wpWpsObjectType!.toJson();
    if (wpWpsQuery != null) data['wp_wps_query'] = wpWpsQuery!.toJson();
    if (wpWpsUri != null) data['wp_wps_uri'] = wpWpsUri!.toJson();
    if (wpWpsUserAgent != null) data['wp_wps_user_agent'] = wpWpsUserAgent!.toJson();
    if (wpWwsAnalytics != null) data['wp_wws_analytics'] = wpWwsAnalytics!.toJson();
    if (wpYithWcwl != null) data['wp_yith_wcwl'] = wpYithWcwl!.toJson();
    if (wpYithWcwlItemmeta != null) data['wp_yith_wcwl_itemmeta'] = wpYithWcwlItemmeta!.toJson();
    if (wpYithWcwlLists != null) data['wp_yith_wcwl_lists'] = wpYithWcwlLists!.toJson();
    return data;
  }
}

class DatabaseSize {
  double? data;
  double? index;

  DatabaseSize({this.data, this.index});

  DatabaseSize.fromJson(Map<String, dynamic> json) {
    data = json['data'] is num ? (json['data'] as num).toDouble() : null;
    index = json['index'] is num ? (json['index'] as num).toDouble() : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['data'] = this.data;
    data['index'] = index;
    return data;
  }
}

class ActivePlugins {
  String? plugin;
  String? name;
  String? version;
  String? versionLatest;
  String? url;
  String? authorName;
  String? authorUrl;
  bool? networkActivated;

  ActivePlugins({
    this.plugin,
    this.name,
    this.version,
    this.versionLatest,
    this.url,
    this.authorName,
    this.authorUrl,
    this.networkActivated,
  });

  ActivePlugins.fromJson(Map<String, dynamic> json) {
    plugin = json['plugin']?.toString();
    name = json['name']?.toString();
    version = json['version']?.toString();
    versionLatest = json['version_latest']?.toString();
    url = json['url']?.toString();
    authorName = json['author_name']?.toString();
    authorUrl = json['author_url']?.toString();
    networkActivated = json['network_activated'] as bool?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['plugin'] = plugin;
    data['name'] = name;
    data['version'] = version;
    data['version_latest'] = versionLatest;
    data['url'] = url;
    data['author_name'] = authorName;
    data['author_url'] = authorUrl;
    data['network_activated'] = networkActivated;
    return data;
  }
}

class InactivePlugins {
  String? plugin;
  String? name;
  String? version;
  String? versionLatest;
  String? url;
  String? authorName;
  String? authorUrl;
  bool? networkActivated;

  InactivePlugins({
    this.plugin,
    this.name,
    this.version,
    this.versionLatest,
    this.url,
    this.authorName,
    this.authorUrl,
    this.networkActivated,
  });

  InactivePlugins.fromJson(Map<String, dynamic> json) {
    plugin = json['plugin']?.toString();
    name = json['name']?.toString();
    version = json['version']?.toString();
    versionLatest = json['version_latest']?.toString();
    url = json['url']?.toString();
    authorName = json['author_name']?.toString();
    authorUrl = json['author_url']?.toString();
    networkActivated = json['network_activated'] as bool?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['plugin'] = plugin;
    data['name'] = name;
    data['version'] = version;
    data['version_latest'] = versionLatest;
    data['url'] = url;
    data['author_name'] = authorName;
    data['author_url'] = authorUrl;
    data['network_activated'] = networkActivated;
    return data;
  }
}

class DropinsMuPlugins {
  List<Dropins>? dropins;
  List<dynamic>? muPlugins;

  DropinsMuPlugins({this.dropins, this.muPlugins});

  DropinsMuPlugins.fromJson(Map<String, dynamic> json) {
    if (json['dropins'] != null) {
      dropins = <Dropins>[];
      for (final v in (json['dropins'] as List)) {
        if (v is Map<String, dynamic>) {
          dropins!.add(Dropins.fromJson(v));
        }
      }
    }
    if (json['mu_plugins'] != null) {
      muPlugins = <dynamic>[];
      for (final v in (json['mu_plugins'] as List)) {
        muPlugins!.add(v);
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (dropins != null) {
      data['dropins'] = dropins!.map((v) => v.toJson()).toList();
    }
    if (muPlugins != null) {
      data['mu_plugins'] = muPlugins;
    }
    return data;
  }
}

class Dropins {
  String? plugin;
  String? name;

  Dropins({this.plugin, this.name});

  Dropins.fromJson(Map<String, dynamic> json) {
    plugin = json['plugin']?.toString();
    name = json['name']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['plugin'] = plugin;
    data['name'] = name;
    return data;
  }
}

class Theme {
  String? name;
  String? version;
  String? versionLatest;
  String? authorUrl;
  bool? isChildTheme;
  bool? isBlockTheme;
  bool? hasWoocommerceSupport;
  bool? hasWoocommerceFile;
  bool? hasOutdatedTemplates;
  List<Overrides>? overrides;
  String? parentName;
  String? parentVersion;
  String? parentVersionLatest;
  String? parentAuthorUrl;

  Theme({
    this.name,
    this.version,
    this.versionLatest,
    this.authorUrl,
    this.isChildTheme,
    this.isBlockTheme,
    this.hasWoocommerceSupport,
    this.hasWoocommerceFile,
    this.hasOutdatedTemplates,
    this.overrides,
    this.parentName,
    this.parentVersion,
    this.parentVersionLatest,
    this.parentAuthorUrl,
  });

  Theme.fromJson(Map<String, dynamic> json) {
    name = json['name']?.toString();
    version = json['version']?.toString();
    versionLatest = json['version_latest']?.toString();
    authorUrl = json['author_url']?.toString();
    isChildTheme = json['is_child_theme'] as bool?;
    isBlockTheme = json['is_block_theme'] as bool?;
    hasWoocommerceSupport = json['has_woocommerce_support'] as bool?;
    hasWoocommerceFile = json['has_woocommerce_file'] as bool?;
    hasOutdatedTemplates = json['has_outdated_templates'] as bool?;
    if (json['overrides'] != null) {
      overrides = <Overrides>[];
      for (final v in (json['overrides'] as List)) {
        if (v is Map<String, dynamic>) {
          overrides!.add(Overrides.fromJson(v));
        }
      }
    }
    parentName = json['parent_name']?.toString();
    parentVersion = json['parent_version']?.toString();
    parentVersionLatest = json['parent_version_latest']?.toString();
    parentAuthorUrl = json['parent_author_url']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['version'] = version;
    data['version_latest'] = versionLatest;
    data['author_url'] = authorUrl;
    data['is_child_theme'] = isChildTheme;
    data['is_block_theme'] = isBlockTheme;
    data['has_woocommerce_support'] = hasWoocommerceSupport;
    data['has_woocommerce_file'] = hasWoocommerceFile;
    data['has_outdated_templates'] = hasOutdatedTemplates;
    if (overrides != null) {
      data['overrides'] = overrides!.map((v) => v.toJson()).toList();
    }
    data['parent_name'] = parentName;
    data['parent_version'] = parentVersion;
    data['parent_version_latest'] = parentVersionLatest;
    data['parent_author_url'] = parentAuthorUrl;
    return data;
  }
}

class Overrides {
  String? file;
  String? version;
  String? coreVersion;

  Overrides({this.file, this.version, this.coreVersion});

  Overrides.fromJson(Map<String, dynamic> json) {
    file = json['file']?.toString();
    version = json['version']?.toString();
    coreVersion = json['core_version']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['file'] = file;
    data['version'] = version;
    data['core_version'] = coreVersion;
    return data;
  }
}

class Settings {
  bool? apiEnabled;
  bool? forceSsl;
  String? currency;
  String? currencySymbol;
  String? currencyPosition;
  String? thousandSeparator;
  String? decimalSeparator;
  int? numberOfDecimals;
  bool? geolocationEnabled;
  Taxonomies? taxonomies;
  ProductVisibilityTerms? productVisibilityTerms;
  String? woocommerceComConnected;
  bool? enforceApprovedDownloadDirs;
  String? orderDatastore;
  bool? hPOSEnabled;
  bool? hPOSSyncEnabled;
  List<String>? enabledFeatures;

  Settings({
    this.apiEnabled,
    this.forceSsl,
    this.currency,
    this.currencySymbol,
    this.currencyPosition,
    this.thousandSeparator,
    this.decimalSeparator,
    this.numberOfDecimals,
    this.geolocationEnabled,
    this.taxonomies,
    this.productVisibilityTerms,
    this.woocommerceComConnected,
    this.enforceApprovedDownloadDirs,
    this.orderDatastore,
    this.hPOSEnabled,
    this.hPOSSyncEnabled,
    this.enabledFeatures,
  });

  Settings.fromJson(Map<String, dynamic> json) {
    apiEnabled = json['api_enabled'] as bool?;
    forceSsl = json['force_ssl'] as bool?;
    currency = json['currency']?.toString();
    currencySymbol = json['currency_symbol']?.toString();
    currencyPosition = json['currency_position']?.toString();
    thousandSeparator = json['thousand_separator']?.toString();
    decimalSeparator = json['decimal_separator']?.toString();
    numberOfDecimals = json['number_of_decimals'] is num
        ? (json['number_of_decimals'] as num).toInt()
        : null;
    geolocationEnabled = json['geolocation_enabled'] as bool?;
    taxonomies = json['taxonomies'] != null
        ? Taxonomies.fromJson(json['taxonomies'] as Map<String, dynamic>)
        : null;
    productVisibilityTerms = json['product_visibility_terms'] != null
        ? ProductVisibilityTerms.fromJson(
            json['product_visibility_terms'] as Map<String, dynamic>)
        : null;
    woocommerceComConnected = json['woocommerce_com_connected']?.toString();
    enforceApprovedDownloadDirs = json['enforce_approved_download_dirs'] as bool?;
    orderDatastore = json['order_datastore']?.toString();
    hPOSEnabled = json['HPOS_enabled'] as bool?;
    hPOSSyncEnabled = json['HPOS_sync_enabled'] as bool?;
    if (json['enabled_features'] != null && json['enabled_features'] is List) {
      enabledFeatures = (json['enabled_features'] as List).cast<String>();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['api_enabled'] = apiEnabled;
    data['force_ssl'] = forceSsl;
    data['currency'] = currency;
    data['currency_symbol'] = currencySymbol;
    data['currency_position'] = currencyPosition;
    data['thousand_separator'] = thousandSeparator;
    data['decimal_separator'] = decimalSeparator;
    data['number_of_decimals'] = numberOfDecimals;
    data['geolocation_enabled'] = geolocationEnabled;
    if (taxonomies != null) {
      data['taxonomies'] = taxonomies!.toJson();
    }
    if (productVisibilityTerms != null) {
      data['product_visibility_terms'] = productVisibilityTerms!.toJson();
    }
    data['woocommerce_com_connected'] = woocommerceComConnected;
    data['enforce_approved_download_dirs'] = enforceApprovedDownloadDirs;
    data['order_datastore'] = orderDatastore;
    data['HPOS_enabled'] = hPOSEnabled;
    data['HPOS_sync_enabled'] = hPOSSyncEnabled;
    data['enabled_features'] = enabledFeatures;
    return data;
  }
}

class Taxonomies {
  String? external;
  String? grouped;
  String? simple;
  String? variable;

  Taxonomies({this.external, this.grouped, this.simple, this.variable});

  Taxonomies.fromJson(Map<String, dynamic> json) {
    external = json['external']?.toString();
    grouped = json['grouped']?.toString();
    simple = json['simple']?.toString();
    variable = json['variable']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['external'] = external;
    data['grouped'] = grouped;
    data['simple'] = simple;
    data['variable'] = variable;
    return data;
  }
}

class ProductVisibilityTerms {
  String? excludeFromCatalog;
  String? excludeFromSearch;
  String? featured;
  String? outofstock;
  String? rated1;
  String? rated2;
  String? rated3;
  String? rated4;
  String? rated5;

  ProductVisibilityTerms({
    this.excludeFromCatalog,
    this.excludeFromSearch,
    this.featured,
    this.outofstock,
    this.rated1,
    this.rated2,
    this.rated3,
    this.rated4,
    this.rated5,
  });

  ProductVisibilityTerms.fromJson(Map<String, dynamic> json) {
    excludeFromCatalog = json['exclude-from-catalog']?.toString();
    excludeFromSearch = json['exclude-from-search']?.toString();
    featured = json['featured']?.toString();
    outofstock = json['outofstock']?.toString();
    rated1 = json['rated-1']?.toString();
    rated2 = json['rated-2']?.toString();
    rated3 = json['rated-3']?.toString();
    rated4 = json['rated-4']?.toString();
    rated5 = json['rated-5']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['exclude-from-catalog'] = excludeFromCatalog;
    data['exclude-from-search'] = excludeFromSearch;
    data['featured'] = featured;
    data['outofstock'] = outofstock;
    data['rated-1'] = rated1;
    data['rated-2'] = rated2;
    data['rated-3'] = rated3;
    data['rated-4'] = rated4;
    data['rated-5'] = rated5;
    return data;
  }
}

class Security {
  bool? secureConnection;
  bool? hideErrors;

  Security({this.secureConnection, this.hideErrors});

  Security.fromJson(Map<String, dynamic> json) {
    secureConnection = json['secure_connection'] as bool?;
    hideErrors = json['hide_errors'] as bool?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['secure_connection'] = secureConnection;
    data['hide_errors'] = hideErrors;
    return data;
  }
}

class Pages {
  String? pageName;
  String? pageId;
  bool? pageSet;
  bool? pageExists;
  bool? pageVisible;
  String? shortcode;
  String? block;
  bool? shortcodeRequired;
  bool? shortcodePresent;
  bool? blockPresent;
  bool? blockRequired;

  Pages({
    this.pageName,
    this.pageId,
    this.pageSet,
    this.pageExists,
    this.pageVisible,
    this.shortcode,
    this.block,
    this.shortcodeRequired,
    this.shortcodePresent,
    this.blockPresent,
    this.blockRequired,
  });

  Pages.fromJson(Map<String, dynamic> json) {
    pageName = json['page_name']?.toString();
    pageId = json['page_id']?.toString();
    pageSet = json['page_set'] as bool?;
    pageExists = json['page_exists'] as bool?;
    pageVisible = json['page_visible'] as bool?;
    shortcode = json['shortcode']?.toString();
    block = json['block']?.toString();
    shortcodeRequired = json['shortcode_required'] as bool?;
    shortcodePresent = json['shortcode_present'] as bool?;
    blockPresent = json['block_present'] as bool?;
    blockRequired = json['block_required'] as bool?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['page_name'] = pageName;
    data['page_id'] = pageId;
    data['page_set'] = pageSet;
    data['page_exists'] = pageExists;
    data['page_visible'] = pageVisible;
    data['shortcode'] = shortcode;
    data['block'] = block;
    data['shortcode_required'] = shortcodeRequired;
    data['shortcode_present'] = shortcodePresent;
    data['block_present'] = blockPresent;
    data['block_required'] = blockRequired;
    return data;
  }
}

class PostTypeCounts {
  String? type;
  String? count;

  PostTypeCounts({this.type, this.count});

  PostTypeCounts.fromJson(Map<String, dynamic> json) {
    type = json['type']?.toString();
    count = json['count']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['count'] = count;
    return data;
  }
}

class Logging {
  bool? loggingEnabled;
  String? defaultHandler;
  int? retentionPeriodDays;
  String? levelThreshold;
  String? logDirectorySize;

  Logging({
    this.loggingEnabled,
    this.defaultHandler,
    this.retentionPeriodDays,
    this.levelThreshold,
    this.logDirectorySize,
  });

  Logging.fromJson(Map<String, dynamic> json) {
    loggingEnabled = json['logging_enabled'] as bool?;
    defaultHandler = json['default_handler']?.toString();
    retentionPeriodDays = json['retention_period_days'] is num
        ? (json['retention_period_days'] as num).toInt()
        : null;
    levelThreshold = json['level_threshold']?.toString();
    logDirectorySize = json['log_directory_size']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['logging_enabled'] = loggingEnabled;
    data['default_handler'] = defaultHandler;
    data['retention_period_days'] = retentionPeriodDays;
    data['level_threshold'] = levelThreshold;
    data['log_directory_size'] = logDirectorySize;
    return data;
  }
}

/// Domain model representing summarized environment and server status for UI presentation.
class SystemStatus extends Equatable {
  final String homeUrl;
  final String siteUrl;
  final String wcVersion;
  final String wpVersion;
  final String phpVersion;
  final String serverInfo;
  final String mysqlVersion;
  final bool isSecure;
  final bool isDebugMode;
  final String currency;
  final String currencySymbol;
  final int activePluginsCount;
  final String themeName;
  final String themeVersion;
  final int responseTimeMs;
  final DateTime checkedAt;

  const SystemStatus({
    required this.homeUrl,
    required this.siteUrl,
    required this.wcVersion,
    required this.wpVersion,
    required this.phpVersion,
    required this.serverInfo,
    required this.mysqlVersion,
    required this.isSecure,
    required this.isDebugMode,
    required this.currency,
    required this.currencySymbol,
    required this.activePluginsCount,
    required this.themeName,
    required this.themeVersion,
    required this.responseTimeMs,
    required this.checkedAt,
  });

  factory SystemStatus.fromJson(Map<String, dynamic> json, {int responseTimeMs = 0}) {
    final getModel = GETSystemStatusModel.fromJson(json);
    return getModel.toDomain(responseTimeMs: responseTimeMs);
  }

  factory SystemStatus.fromGetModel(GETSystemStatusModel model, {int responseTimeMs = 0}) {
    return model.toDomain(responseTimeMs: responseTimeMs);
  }

  @override
  List<Object?> get props => [
        homeUrl,
        siteUrl,
        wcVersion,
        wpVersion,
        phpVersion,
        serverInfo,
        mysqlVersion,
        isSecure,
        isDebugMode,
        currency,
        currencySymbol,
        activePluginsCount,
        themeName,
        themeVersion,
        responseTimeMs,
        checkedAt,
      ];
}
