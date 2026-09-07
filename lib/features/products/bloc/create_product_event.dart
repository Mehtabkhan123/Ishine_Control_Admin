import 'package:equatable/equatable.dart';
import '../data/models/post_create_model.dart';

abstract class CreateProductEvent extends Equatable {
  const CreateProductEvent();

  @override
  List<Object?> get props => [];
}

/// Loads available categories and tags for the Add Product form picker.
class CreateProductTaxonomiesRequested extends CreateProductEvent {
  const CreateProductTaxonomiesRequested();
}

/// Submits the product creation request to WooCommerce API:
/// `POST /wp-json/wc/v3/products`
class CreateProductSubmitted extends CreateProductEvent {
  final PostCreateModel product;

  const CreateProductSubmitted(this.product);

  @override
  List<Object?> get props => [product];
}

/// Resets the submission state (e.g. after navigating or dismissing an error).
class CreateProductReset extends CreateProductEvent {
  const CreateProductReset();
}
