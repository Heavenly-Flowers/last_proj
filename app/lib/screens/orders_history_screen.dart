import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void initState() {
    super.initState();

    loadOrders();
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
                final items = (order['order_items'] as List?) ?? [];

                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Заказ #${order['id']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'Статус: ${order['status']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Сумма: ${order['total_price']} ₽',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'Состав:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        ...List.generate(items.length, (itemIndex) {
                          final item = items[itemIndex] as Map<String, dynamic>;
                          final toppingLinks =
                              (item['order_item_toppings'] as List?) ?? [];
                          final toppingNames = toppingLinks
                              .map((link) {
                                final topping =
                                    (link as Map<String, dynamic>)['toppings']
                                        as Map<String, dynamic>?;

                                return topping?['name'] as String?;
                              })
                              .whereType<String>()
                              .toList();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              toppingNames.isEmpty
                                  ? '${item['coffee_title']} (${item['size']}) - ${item['price']} ₽'
                                  : '${item['coffee_title']} (${item['size']}) - ${item['price']} ₽, допинги: ${toppingNames.join(", ")}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
