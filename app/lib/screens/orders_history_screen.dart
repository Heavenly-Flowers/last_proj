import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'order_status_screen.dart';

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  final supabase = Supabase.instance.client;

  List orders = [];

  bool isLoading = true;
  String? errorMessage;
  RealtimeChannel? channel;

  @override
  void initState() {
    super.initState();

    loadOrders();
    listenOrderStatuses();
  }

  @override
  void dispose() {
    if (channel != null) {
      supabase.removeChannel(channel!);
    }

    super.dispose();
  }

  Future<void> loadOrders() async {
    try {
      final response = await supabase
          .from('orders')
          .select('''
          id,
          status,
          total_price,
          created_at,
          order_items (
            id,
            coffee_title,
            size,
            price,
            order_item_toppings (
              toppings (
                id,
                name,
                price
              )
            )
          )
        ''')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        orders = response;
        errorMessage = null;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Не удалось загрузить заказы';
        isLoading = false;
      });
    }
  }

  void listenOrderStatuses() {
    channel = supabase
        .channel('orders_history_statuses')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            final updatedOrder = payload.newRecord;
            final updatedOrderId = updatedOrder['id']?.toString();

            if (updatedOrderId == null) {
              return;
            }

            final orderIndex = orders.indexWhere(
              (order) =>
                  (order as Map<String, dynamic>)['id'].toString() ==
                  updatedOrderId,
            );

            if (orderIndex == -1 || !mounted) {
              return;
            }

            setState(() {
              final currentOrder = orders[orderIndex] as Map<String, dynamic>;

              orders[orderIndex] = {
                ...currentOrder,
                'status': updatedOrder['status'],
              };
            });
          },
        );

    channel!.subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text('Мои заказы'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 22),
              ),
            )
          : orders.isEmpty
          ? const Center(
              child: Text(
                'Заказов пока нет',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
            )
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index] as Map<String, dynamic>;

                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              OrderStatusScreen(orderId: order['id'] as int),
                        ),
                      );

                      if (!mounted) return;

                      loadOrders();
                    },
                    title: Text(
                      'Заказ #${order['id']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Время: ${formatOrderDate(order['created_at'])}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Статус: ${order['status']}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Сумма: ${formatPrice(order['total_price'])} ₽',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.white70,
                    ),
                  ),
                );
              },
            ),
    );
  }

  String formatOrderDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();

    if (date == null) {
      return 'неизвестно';
    }

    return '${twoDigits(date.day)}.${twoDigits(date.month)}.${date.year} '
        '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }

  String formatPrice(dynamic value) {
    final price = num.tryParse(value.toString());

    if (price == null) {
      return value.toString();
    }

    return price.toStringAsFixed(0);
  }

  String twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}
