import 'package:supabase_flutter/supabase_flutter.dart';

import '../cart/cart_item.dart';

class OrderService {
  SupabaseClient get supabase => Supabase.instance.client;

  Future<int> createOrder(List<CartItem> items, double totalPrice) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'Для оформления заказа необходимо войти в аккаунт',
      );
    }

    final orderItems = items.map((item) {
      return {
        'coffee': item.coffee.title,
        'size': item.size.code,
        'toppings': item.toppings.map((topping) => topping.name).toList(),
        'price': item.totalPrice,
      };
    }).toList();

    final response = await supabase
        .from('orders')
        .insert({
          'user_id': user.id,
          'items': orderItems,
          'total_price': totalPrice,
        })
        .select()
        .single();

    return (response['id'] as num).toInt();
  }

  Future<List<Map<String, dynamic>>> getCurrentUserOrders() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw const AuthException('Пользователь не авторизован');
    }

    final response = await supabase
        .from('orders')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
