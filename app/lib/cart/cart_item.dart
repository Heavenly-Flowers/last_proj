import '../models/coffee.dart';
import '../models/coffee_option.dart';

class CartItem {
  final Coffee coffee;
  final CoffeeSizeOption size;
  final List<ToppingOption> toppings;
  final int quantity;

  CartItem({
    required this.coffee,
    required this.size,
    required List<ToppingOption> toppings,
    this.quantity = 1,
  }) : toppings = List.unmodifiable(toppings);

  double get toppingsPrice {
    return toppings.fold(0, (sum, topping) => sum + topping.price);
  }

  double get unitPrice {
    return coffee.price + size.extraPrice + toppingsPrice;
  }

  double get totalPrice => unitPrice * quantity;
}
