import '../models/coffee.dart';

class CartItem {
  final Coffee coffee;
  final String size;
  final List<String> toppings;
  final int quantity;

  CartItem({
    required this.coffee,
    required this.size,
    required this.toppings,
    this.quantity = 1,
  });

  double get totalPrice {
    double price = coffee.price;

    if (size == 'M') {
      price += 30;
    }

    if (size == 'L') {
      price += 60;
    }

    price += toppings.length * 20;

    return price * quantity;
  }
}