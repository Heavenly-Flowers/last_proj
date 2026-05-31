import 'cart_item.dart';

class CartService {
  static final CartService instance =
      CartService._internal();

  CartService._internal();

  final List<CartItem> items = [];

  void addItem(CartItem item) {
    items.add(item);
  }

  void clear() {
  items.clear();
  }

  double get totalPrice {
    return items.fold(
      0,
      (sum, item) => sum + item.totalPrice,
    );
  }
}