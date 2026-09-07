import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
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

    test('toProductImageRefs converts items to ProductImageRef list for WooCommerce', () {
      final cubit = GalleryUploadCubit(repository: mockRepository);
      final initialImages = [
        ProductImageRef(id: 1, src: 'https://example.com/1.jpg', name: 'Photo 1'),
        ProductImageRef(id: 2, src: 'https://example.com/2.jpg', name: 'Photo 2'),
      ];

      cubit.setInitialImages(initialImages);
      final refs = cubit.state.toProductImageRefs();

      expect(refs.length, 2);
      expect(refs[0].id, 1);
      expect(refs[0].src, 'https://example.com/1.jpg');
      expect(refs[1].id, 2);
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
      // Inject a local pending item into state
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
  });
}
