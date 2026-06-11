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

  String status = 'обработка оплаты';

  RealtimeChannel? channel;

  @override
  void initState() {
    super.initState();

    loadOrder();

    listenStatus();
  }

  Future<void> loadOrder() async {
    final response = await supabase
        .from('orders')
        .select()
        .eq('id', widget.orderId)
        .single();

    if (!mounted) return;

    setState(() {
      status = response['status'];
    });
  }

  void listenStatus() {
    channel = supabase
        .channel('orders_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            final newData = payload.newRecord;

            if (newData['id'].toString() == widget.orderId.toString()) {
              if (!mounted) return;

              setState(() {
                status = newData['status'];
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
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text('Статус заказа'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Ваш заказ',
              style: TextStyle(color: Colors.white70, fontSize: 22),
            ),

            const SizedBox(height: 20),

            Text(
              status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
