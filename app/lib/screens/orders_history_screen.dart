import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  State<OrdersHistoryScreen> createState() =>
      _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState
    extends State<OrdersHistoryScreen> {

  final supabase = Supabase.instance.client;

  List orders = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    loadOrders();
  }

  Future<void> loadOrders() async {

    final response = await supabase
        .from('orders')
        .select()
        .order(
          'created_at',
          ascending: false,
        );

    setState(() {
      orders = response;
      isLoading = false;
    });
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
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : orders.isEmpty
              ? const Center(
                  child: Text(
                    'Заказов пока нет',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {

                    final order = orders[index];

                    return Card(
                      color: Colors.grey[900],
                      margin:
                          const EdgeInsets.all(12),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            Text(
                              'Заказ #${order['id']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'Статус: ${order['status']}',
                              style: const TextStyle(
                                color:
                                    Colors.white70,
                                fontSize: 18,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'Сумма: ${order['total_price']} ₽',
                              style: const TextStyle(
                                color:
                                    Colors.white70,
                                fontSize: 18,
                              ),
                            ),

                            const SizedBox(height: 12),

                            const Text(
                              'Состав:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            ...List.generate(
                              order['items'].length,
                              (itemIndex) {

                                final item =
                                    order['items']
                                        [itemIndex];

                                return Padding(
                                  padding:
                                      const EdgeInsets.only(
                                    bottom: 6,
                                  ),
                                  child: Text(
                                    '${item['coffee']} (${item['size']})',
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white70,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}