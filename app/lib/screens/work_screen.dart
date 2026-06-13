import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'order_status_screen.dart';

class WorkScreen extends StatefulWidget {
  const WorkScreen({super.key});

  @override
  State<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends State<WorkScreen> {
  final supabase = Supabase.instance.client;

  static const activeStatuses = [
    'обработка оплаты',
    'принят',
    'готовится',
    'готов',
  ];

  List activeOrders = [];
  List readyOrders = [];

  bool isLoading = true;
  String? errorMessage;
  RealtimeChannel? channel;

  @override
  void initState() {
    super.initState();
    loadOrders();
    listenOrders();
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
            user_id,
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
          .neq('status', 'выдан')
          .order('created_at', ascending: true);

      if (!mounted) return;

      setState(() {
        activeOrders = response
            .where((order) => order['status'] != 'готов')
            .toList();
        readyOrders = response
            .where((order) => order['status'] == 'готов')
            .toList();
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

  void listenOrders() {
    channel = supabase
        .channel('work_orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (_) {
            loadOrders();
          },
        );

    channel!.subscribe();
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    try {
      await supabase
          .from('orders')
          .update({'status': status})
          .eq('id', orderId);

      await loadOrders();
      showMessage('Статус обновлен');
    } catch (_) {
      showMessage('Не удалось обновить статус');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Работа'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Активные'),
              Tab(text: 'Готовые'),
            ],
          ),
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
            : TabBarView(
                children: [
                  buildOrdersList(
                    activeOrders,
                    emptyText: 'Активных заказов нет',
                    showStatusSelector: true,
                  ),
                  buildOrdersList(
                    readyOrders,
                    emptyText: 'Готовых заказов нет',
                    showStatusSelector: false,
                  ),
                ],
              ),
      ),
    );
  }

  Widget buildOrdersList(
    List orders, {
    required String emptyText,
    required bool showStatusSelector,
  }) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: const TextStyle(color: Colors.white, fontSize: 22),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadOrders,
      child: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index] as Map<String, dynamic>;

          return orderCard(order, showStatusSelector: showStatusSelector);
        },
      ),
    );
  }

  Widget orderCard(
    Map<String, dynamic> order, {
    required bool showStatusSelector,
  }) {
    final orderId = order['id'] as int;
    final status = order['status'] as String;

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.all(12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrderStatusScreen(orderId: orderId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Заказ #$orderId',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${formatPrice(order['total_price'])} ₽',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Время: ${formatDate(order['created_at'])}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                'Статус: $status',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              ...buildOrderItems(order),
              const SizedBox(height: 12),
              if (showStatusSelector)
                statusDropdown(orderId: orderId, status: status)
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      updateOrderStatus(orderId, 'выдан');
                    },
                    child: const Text('Отметить как выдан'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget statusDropdown({required int orderId, required String status}) {
    return DropdownButtonFormField<String>(
      initialValue: activeStatuses.contains(status)
          ? status
          : activeStatuses.first,
      dropdownColor: Colors.grey[900],
      decoration: const InputDecoration(
        labelText: 'Изменить готовность',
        border: OutlineInputBorder(),
      ),
      items: activeStatuses
          .map(
            (status) =>
                DropdownMenuItem<String>(value: status, child: Text(status)),
          )
          .toList(),
      onChanged: (newStatus) {
        if (newStatus == null || newStatus == status) {
          return;
        }

        updateOrderStatus(orderId, newStatus);
      },
    );
  }

  List<Widget> buildOrderItems(Map<String, dynamic> order) {
    final items = (order['order_items'] as List?) ?? [];

    if (items.isEmpty) {
      return [
        const Text(
          'Состав заказа пуст',
          style: TextStyle(color: Colors.white70),
        ),
      ];
    }

    return items.map((itemData) {
      final item = itemData as Map<String, dynamic>;
      final toppingNames = getToppingNames(item);

      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          toppingNames.isEmpty
              ? '${item['coffee_title']} (${item['size']})'
              : '${item['coffee_title']} (${item['size']}), допинги: ${toppingNames.join(", ")}',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }).toList();
  }

  List<String> getToppingNames(Map<String, dynamic> item) {
    final toppingLinks = (item['order_item_toppings'] as List?) ?? [];

    return toppingLinks
        .map((link) {
          final topping =
              (link as Map<String, dynamic>)['toppings']
                  as Map<String, dynamic>?;

          return topping?['name'] as String?;
        })
        .whereType<String>()
        .toList();
  }

  String formatDate(dynamic value) {
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
