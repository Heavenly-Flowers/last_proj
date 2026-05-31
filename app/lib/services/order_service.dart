import 'package:supabase_flutter/supabase_flutter.dart';

import '../cart/cart_item.dart';

class OrderService {

  final supabase = Supabase.instance.client;

  Future<void> createOrder(
    List<CartItem> items,
    double totalPrice,
  ) async {

    final orderItems = items.map((item) {
      return {
        'coffee': item.coffee.title,
        'size': item.size,
        'toppings': item.toppings,
        'price': item.totalPrice,
      };
    }).toList();

    final response = await supabase
        .from('orders')
        .insert({
          'items': orderItems,
          'total_price': totalPrice,
        })
        .select();

    print(response);
  }
}