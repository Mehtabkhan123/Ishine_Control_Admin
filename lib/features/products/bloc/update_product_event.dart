import 'package:equatable/equatable.dart';
import '../data/models/put_update_model.dart';

abstract class UpdateProductEvent extends Equatable {
  const UpdateProductEvent();

  @override
  List<Object?> get props => [];
}

/// Loads available categories and tags for the Edit Product form picker.
class UpdateProductTaxonomiesRequested extends UpdateProductEvent {
  const UpdateProductTaxonomiesRequested();
}

/// Fetches an existing product from WooCommerce by ID to edit.
class UpdateProductFetchRequested extends UpdateProductEvent {
  final int productId;

  const UpdateProductFetchRequested(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// Submits the product update request to WooCommerce API:
/// `PUT /wp-json/wc/v3/products/{{productId}}`
class UpdateProductSubmitted extends UpdateProductEvent {
  final int productId;
  final PutUpdateModel product;

  const UpdateProductSubmitted({
    required this.productId,
    required this.product,
  });

  @override
  List<Object?> get props => [productId, product];
}

/// Resets the update state.
class UpdateProductReset extends UpdateProductEvent {
  const UpdateProductReset();
}
