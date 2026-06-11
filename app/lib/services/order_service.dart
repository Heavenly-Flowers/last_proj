import 'dart:async';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../cart/cart_item.dart';

class OrderService {
  final supabase = Supabase.instance.client;
  final Random _random = Random();

  static const List<String> statuses = [
    'обработка оплаты',
    'принят',
    'готовится',
    'готов',
    'выдан',
  ];

  Future<int> createOrder(List<CartItem> items, double totalPrice) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw StateError('Пользователь не авторизован');
    }

    final order = await supabase
        .from('orders')
        .insert({
          'user_id': user.id,
          'status': statuses.first,
          'total_price': totalPrice,
        })
        .select('id')
        .single();

    final orderId = order['id'] as int;
    final toppingIdsByName = await _loadToppingIds(items);

    for (final item in items) {
      final orderItem = await supabase
          .from('order_items')
          .insert({
            'order_id': orderId,
            'coffee_title': item.coffee.title,
            'size': item.size,
            'price': item.totalPrice,
          })
          .select('id')
          .single();

      final orderItemId = orderItem['id'] as int;
      final selectedToppingIds = item.toppings
          .map((name) => toppingIdsByName[name])
          .whereType<int>()
          .toList();

      if (selectedToppingIds.length != item.toppings.length) {
        throw StateError('Не все допинги найдены в базе данных');
      }

      if (selectedToppingIds.isNotEmpty) {
        await supabase
            .from('order_item_toppings')
            .insert(
              selectedToppingIds
                  .map(
                    (toppingId) => {
                      'order_item_id': orderItemId,
                      'topping_id': toppingId,
                    },
                  )
                  .toList(),
            );
      }
    }

    unawaited(_advanceOrderStatuses(orderId));

    return orderId;
  }

  Future<Map<String, int>> _loadToppingIds(List<CartItem> items) async {
    final toppingNames = items.expand((item) => item.toppings).toSet().toList();

    if (toppingNames.isEmpty) {
      return {};
    }

    final response = await supabase
        .from('toppings')
        .select('id, name')
        .inFilter('name', toppingNames);

    return {
      for (final topping in response)
        topping['name'] as String: topping['id'] as int,
    };
  }

  Future<void> _advanceOrderStatuses(int orderId) async {
    try {
      for (final status in statuses.skip(1)) {
        final delaySeconds = 4 + _random.nextInt(7);
        await Future.delayed(Duration(seconds: delaySeconds));

        await supabase
            .from('orders')
            .update({'status': status})
            .eq('id', orderId);
      }
    } catch (_) {
      return;
    }
  }
}
