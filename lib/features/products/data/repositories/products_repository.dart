import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../system_status/data/services/system_status_service.dart';
import '../models/post_create_model.dart';
import '../models/put_update_model.dart';
import '../services/media_upload_service.dart';
import '../services/products_service.dart';

/// Repository managing WooCommerce Product creation, update, listing, catalog cache, and deduplication.
class ProductsRepository {
  final ProductsService _service;
  final MediaUploadService _mediaService;

  // In-memory cache for product queries
  final Map<String, List<PostCreateModel>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, Future<List<PostCreateModel>>> _inFlightRequests = {};

  // In-memory cache for taxonomy helpers (Categories and Tags)
  List<ProductCategoryRef>? _categoriesCache;
  DateTime? _categoriesCachedAt;
  Future<List<ProductCategoryRef>>? _inFlightCategoriesRequest;

  List<ProductTagRef>? _tagsCache;
  DateTime? _tagsCachedAt;
  Future<List<ProductTagRef>>? _inFlightTagsRequest;

  /// Cache validity duration
  final Duration cacheTtl;

  ProductsRepository({
    ProductsService? service,
    MediaUploadService? mediaService,
    WooCommerceDioClient? dioClient,
    this.cacheTtl = const Duration(minutes: 3),
  })  : _service = service ??
            (dioClient != null
                ? ProductsService(dio: dioClient.dioInstance)
                : ProductsService()),
        _mediaService = mediaService ??
            (dioClient != null
                ? MediaUploadService(dio: dioClient.dioInstance)
                : MediaUploadService());

  /// Creates a new product in WooCommerce and automatically invalidates the product list cache.
  Future<PostCreateModel> createProduct(
    PostCreateModel product, {
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    final createdProduct = await _service.createProduct(
      product: product,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );

    // Invalidate product catalog cache so list immediately updates
    clearCache();

    return createdProduct;
  }

  /// Updates an existing product in WooCommerce: `PUT /wp-json/wc/v3/products/{{id}}`
  /// and automatically invalidates the product list cache.
  Future<PutUpdateModel> updateProduct({
    required int productId,
    required PutUpdateModel product,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    final updatedProduct = await _service.updateProduct(
      productId: productId,
      product: product,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );

    // Invalidate product catalog cache so list immediately reflects updates
    clearCache();

    return updatedProduct;
  }

  /// Fetches a single product by ID from WooCommerce API.
  Future<PutUpdateModel> getProductById({
    required int productId,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    return await _service.fetchProductById(
      productId: productId,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );
  }

  /// Uploads media image bytes to WordPress media repository with progress tracking.
  Future<ProductImageRef> uploadMedia({
    required Uint8List bytes,
    required String filename,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    return await _mediaService.uploadMedia(
      bytes: bytes,
      filename: filename,
      onProgress: onProgress,
      cancelToken: cancelToken,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
    );
  }

  /// Retrieves products with caching and deduplication.
  Future<List<PostCreateModel>> getProducts({
    int page = 1,
    int perPage = 20,
    String? search,
    String? category,
    String? status,
    bool forceRefresh = false,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    final cacheKey = '$page:$perPage:${search ?? ""}:${category ?? ""}:${status ?? ""}';

    // 1. Return cached data if valid and fresh
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final cachedAt = _cacheTimestamps[cacheKey];
      if (cachedAt != null && DateTime.now().difference(cachedAt) < cacheTtl) {
        return _cache[cacheKey]!;
      }
    }

    // 2. Return in-flight future if already running
    if (_inFlightRequests.containsKey(cacheKey)) {
      return _inFlightRequests[cacheKey]!;
    }

    // 3. Initiate new network request
    final requestFuture = _service.fetchProducts(
      page: page,
      perPage: perPage,
      search: search,
      category: category,
      status: status,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );

    _inFlightRequests[cacheKey] = requestFuture;

    try {
      final products = await requestFuture;
      _cache[cacheKey] = products;
      _cacheTimestamps[cacheKey] = DateTime.now();
      return products;
    } finally {
      _inFlightRequests.remove(cacheKey);
    }
  }

  /// Retrieves categories with caching and deduplication.
  Future<List<ProductCategoryRef>> getCategories({
    bool forceRefresh = false,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    if (!forceRefresh && _categoriesCache != null && _categoriesCachedAt != null) {
      if (DateTime.now().difference(_categoriesCachedAt!) < const Duration(minutes: 15)) {
        return _categoriesCache!;
      }
    }

    if (_inFlightCategoriesRequest != null) {
      return _inFlightCategoriesRequest!;
    }

    final requestFuture = _service.fetchCategories(
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );

    _inFlightCategoriesRequest = requestFuture;

    try {
      final categories = await requestFuture;
      _categoriesCache = categories;
      _categoriesCachedAt = DateTime.now();
      return categories;
    } finally {
      _inFlightCategoriesRequest = null;
    }
  }

  /// Retrieves tags with caching and deduplication.
  Future<List<ProductTagRef>> getTags({
    bool forceRefresh = false,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    if (!forceRefresh && _tagsCache != null && _tagsCachedAt != null) {
      if (DateTime.now().difference(_tagsCachedAt!) < const Duration(minutes: 15)) {
        return _tagsCache!;
      }
    }

    if (_inFlightTagsRequest != null) {
      return _inFlightTagsRequest!;
    }

    final requestFuture = _service.fetchTags(
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );

    _inFlightTagsRequest = requestFuture;

    try {
      final tags = await requestFuture;
      _tagsCache = tags;
      _tagsCachedAt = DateTime.now();
      return tags;
    } finally {
      _inFlightTagsRequest = null;
    }
  }

  /// Clears in-memory catalog cache.
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    _inFlightRequests.clear();
  }
}
