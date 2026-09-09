import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/products/bloc/gallery_upload_cubit.dart';
import 'package:ishine_admin_app/features/products/data/models/gallery_image_item.dart';
import 'package:ishine_admin_app/features/products/data/models/post_create_model.dart';
import 'package:ishine_admin_app/features/products/data/repositories/products_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockProductsRepository extends Mock implements ProductsRepository {}

void main() {
  late MockProductsRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockRepository = MockProductsRepository();
  });

  group('GalleryUploadCubit', () {
    test('initial state has empty items, not picking, and not uploading', () {
      final cubit = GalleryUploadCubit(repository: mockRepository);
      expect(cubit.state.items, isEmpty);
      expect(cubit.state.isPicking, isFalse);
      expect(cubit.state.isUploading, isFalse);
      expect(cubit.state.errorMessage, isNull);
    });

    test('setInitialImages seeds existing product images correctly', () {
      final cubit = GalleryUploadCubit(repository: mockRepository);
      final initialImages = [
        ProductImageRef(id: 101, src: 'https://example.com/img1.jpg', name: 'img1'),
        ProductImageRef(id: 102, src: 'https://example.com/img2.jpg', name: 'img2'),
      ];

      cubit.setInitialImages(initialImages);

      expect(cubit.state.items.length, 2);
      expect(cubit.state.items[0].id, 101);
      expect(cubit.state.items[0].remoteUrl, 'https://example.com/img1.jpg');
      expect(cubit.state.items[0].status, GalleryImageStatus.success);

      expect(cubit.state.items[1].id, 102);
      expect(cubit.state.items[1].remoteUrl, 'https://example.com/img2.jpg');
      expect(cubit.state.items[1].status, GalleryImageStatus.success);
    });

    test('addImageUrl adds an image URL directly with success status', () {
      final cubit = GalleryUploadCubit(repository: mockRepository);

      cubit.addImageUrl('https://example.com/product_test.png', name: 'Product Front');

      expect(cubit.state.items.length, 1);
      expect(cubit.state.items.first.remoteUrl, 'https://example.com/product_test.png');
      expect(cubit.state.items.first.name, 'Product Front');
      expect(cubit.state.items.first.status, GalleryImageStatus.success);
      expect(cubit.state.items.first.isUploaded, isTrue);

      final refs = cubit.state.toProductImageRefs();
      expect(refs.length, 1);
      expect(refs.first.src, 'https://example.com/product_test.png');
    });

    test('addImageUrls adds multiple URLs in bulk', () {
      final cubit = GalleryUploadCubit(repository: mockRepository);

      cubit.addImageUrls([
        'https://example.com/photo1.jpg',
        'https://example.com/photo2.jpg',
        '', // empty url should be ignored
      ]);

      expect(cubit.state.items.length, 2);
      expect(cubit.state.items[0].remoteUrl, 'https://example.com/photo1.jpg');
      expect(cubit.state.items[1].remoteUrl, 'https://example.com/photo2.jpg');
    });

    test('setImageUrl links a remote URL to a local item', () {
      final cubit = GalleryUploadCubit(repository: mockRepository);
      final localItem = GalleryImageItem(
        uniqueId: 'local_1',
        name: 'camera_photo.jpg',
        bytes: Uint8List.fromList([1, 2, 3]),
        status: GalleryImageStatus.idle,
      );
      cubit.emit(cubit.state.copyWith(items: [localItem]));
      expect(cubit.state.items.first.isUploaded, isFalse);

      cubit.setImageUrl(0, 'https://example.com/hosted_camera_photo.jpg');

      expect(cubit.state.items.first.remoteUrl, 'https://example.com/hosted_camera_photo.jpg');
      expect(cubit.state.items.first.status, GalleryImageStatus.success);
      expect(cubit.state.items.first.isUploaded, isTrue);
    });

    test('reorder reorders images correctly and preserves order', () {
      final cubit = GalleryUploadCubit(repository: mockRepository);
      final initialImages = [
        ProductImageRef(id: 1, src: 'https://example.com/1.jpg'),
        ProductImageRef(id: 2, src: 'https://example.com/2.jpg'),
        ProductImageRef(id: 3, src: 'https://example.com/3.jpg'),
      ];

      cubit.setInitialImages(initialImages);
      expect(cubit.state.items.first.id, 1);

      // Move index 0 to index 2 (Flutter ReorderableListView semantics)
      cubit.reorder(0, 3);

      expect(cubit.state.items[0].id, 2);
      expect(cubit.state.items[1].id, 3);
      expect(cubit.state.items[2].id, 1);
    });

    test('setAsMain brings selected item to index 0', () {
      final cubit = GalleryUploadCubit(repository: mockRepository);
      final initialImages = [
        ProductImageRef(id: 1, src: 'https://example.com/1.jpg'),
        ProductImageRef(id: 2, src: 'https://example.com/2.jpg'),
        ProductImageRef(id: 3, src: 'https://example.com/3.jpg'),
      ];

      cubit.setInitialImages(initialImages);
      cubit.setAsMain(2); // Set item with id 3 as main

      expect(cubit.state.items[0].id, 3);
      expect(cubit.state.items[1].id, 1);
      expect(cubit.state.items[2].id, 2);
    });

    test('moveLeft and moveRight swap items safely', () {
      final cubit = GalleryUploadCubit(repository: mockRepository);
      final initialImages = [
        ProductImageRef(id: 10, src: 'https://example.com/10.jpg'),
        ProductImageRef(id: 20, src: 'https://example.com/20.jpg'),
      ];

      cubit.setInitialImages(initialImages);

      // Moving index 0 left should be a no-op
      cubit.moveLeft(0);
      expect(cubit.state.items[0].id, 10);

      // Moving index 1 left swaps 0 and 1
      cubit.moveLeft(1);
      expect(cubit.state.items[0].id, 20);
      expect(cubit.state.items[1].id, 10);

      // Moving index 0 right swaps back
      cubit.moveRight(0);
      expect(cubit.state.items[0].id, 10);
      expect(cubit.state.items[1].id, 20);
    });

    test('removeImage removes the item', () {
      final cubit = GalleryUploadCubit(repository: mockRepository);
      final initialImages = [
        ProductImageRef(id: 1, src: 'https://example.com/1.jpg'),
        ProductImageRef(id: 2, src: 'https://example.com/2.jpg'),
      ];

      cubit.setInitialImages(initialImages);
      cubit.removeImage(0);

      expect(cubit.state.items.length, 1);
      expect(cubit.state.items.first.id, 2);
    });

    test('toProductImageRefs converts only ready items to ProductImageRef list', () {
      final cubit = GalleryUploadCubit(repository: mockRepository);
      final items = [
        const GalleryImageItem(
          uniqueId: '1',
          name: 'Ready 1',
          remoteUrl: 'https://example.com/1.jpg',
          status: GalleryImageStatus.success,
        ),
        const GalleryImageItem(
          uniqueId: '2',
          name: 'Local Pending',
          status: GalleryImageStatus.idle,
        ),
        const GalleryImageItem(
          uniqueId: '3',
          name: 'Ready 2',
          remoteUrl: 'https://example.com/2.jpg',
          status: GalleryImageStatus.success,
        ),
      ];

      cubit.emit(cubit.state.copyWith(items: items));
      final refs = cubit.state.toProductImageRefs();

      expect(refs.length, 2);
      expect(refs[0].src, 'https://example.com/1.jpg');
      expect(refs[1].src, 'https://example.com/2.jpg');
    });

    test('uploadPending uploads pending local images successfully', () async {
      when(() => mockRepository.uploadMedia(
            bytes: any(named: 'bytes'),
            filename: any(named: 'filename'),
            onProgress: any(named: 'onProgress'),
            cancelToken: any(named: 'cancelToken'),
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
          )).thenAnswer((_) async => ProductImageRef(
            id: 999,
            src: 'https://example.com/uploaded.jpg',
            name: 'uploaded.jpg',
          ));

      final cubit = GalleryUploadCubit(repository: mockRepository);
      final pendingItem = GalleryImageItem(
        uniqueId: 'pending_1',
        name: 'sample.jpg',
        bytes: Uint8List.fromList([1, 2, 3]),
        status: GalleryImageStatus.idle,
      );
      cubit.emit(cubit.state.copyWith(items: [pendingItem]));

      expect(cubit.state.hasPendingUploads, isTrue);

      await cubit.uploadPending();

      expect(cubit.state.items.first.status, GalleryImageStatus.success);
      expect(cubit.state.items.first.id, 999);
      expect(cubit.state.items.first.remoteUrl, 'https://example.com/uploaded.jpg');
      expect(cubit.state.hasPendingUploads, isFalse);
    });

    test('uploadPending captures upload error gracefully without crashing', () async {
      when(() => mockRepository.uploadMedia(
            bytes: any(named: 'bytes'),
            filename: any(named: 'filename'),
            onProgress: any(named: 'onProgress'),
            cancelToken: any(named: 'cancelToken'),
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
          )).thenThrow(const WooCommerceException(
            message: 'Direct media file upload is not supported by WooCommerce REST API keys.',
            statusCode: 405,
          ));

      final cubit = GalleryUploadCubit(repository: mockRepository);
      final pendingItem = GalleryImageItem(
        uniqueId: 'pending_err',
        name: 'err.jpg',
        bytes: Uint8List.fromList([1, 2, 3]),
        status: GalleryImageStatus.idle,
      );
      cubit.emit(cubit.state.copyWith(items: [pendingItem]));

      await cubit.uploadPending();

      expect(cubit.state.isUploading, isFalse);
      expect(cubit.state.errorMessage, contains('Direct media file upload is not supported'));
      expect(cubit.state.items.first.status, GalleryImageStatus.error);
    });
  });
}
