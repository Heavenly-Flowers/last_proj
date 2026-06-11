import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderStatusScreen extends StatefulWidget {
  final int orderId;

  const OrderStatusScreen({super.key, required this.orderId});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? order;
  String status = 'обработка оплаты';
  bool isLoading = true;
  String? errorMessage;

  RealtimeChannel? channel;

  @override
  void initState() {
    super.initState();

    loadOrder();
    listenStatus();
  }

  Future<void> loadOrder() async {
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
          .eq('id', widget.orderId)
          .single();

      if (!mounted) return;

      setState(() {
        order = response;
        status = response['status'] as String;
        errorMessage = null;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Не удалось загрузить заказ';
        isLoading = false;
      });
    }
  }

  void listenStatus() {
    channel = supabase
        .channel('orders_status_${widget.orderId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            final newData = payload.newRecord;

            if (newData['id'].toString() == widget.orderId.toString()) {
              if (!mounted) return;

              setState(() {
                status = newData['status'] as String;
                order = {...?order, 'status': newData['status']};
              });
            }
          },
        );

    channel!.subscribe();
  }

  @override
  void dispose() {
    if (channel != null) {
      supabase.removeChannel(channel!);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentOrder = order;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Заказ #${widget.orderId}'),
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
          : currentOrder == null
          ? const Center(
              child: Text(
                'Заказ не найден',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Статус готовности',
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                infoRow(
                  'Время заказа',
                  formatOrderDate(currentOrder['created_at']),
                ),
                infoRow(
                  'Сумма',
                  '${formatPrice(currentOrder['total_price'])} ₽',
                ),
                const SizedBox(height: 24),
                const Text(
                  'Состав заказа',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...buildOrderItems(currentOrder),
              ],
            ),
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
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

      return Card(
        color: Colors.grey[900],
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item['coffee_title']} (${item['size']})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                toppingNames.isEmpty
                    ? 'Допинги: нет'
                    : 'Допинги: ${toppingNames.join(", ")}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                '${formatPrice(item['price'])} ₽',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
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
