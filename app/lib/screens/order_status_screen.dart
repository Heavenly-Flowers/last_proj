import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/order_status_progress.dart';

class OrderStatusScreen extends StatefulWidget {
  final int orderId;

  const OrderStatusScreen({super.key, required this.orderId});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  final supabase = Supabase.instance.client;

  String status = 'Обработка';
  String? errorMessage;
  bool isLoading = true;
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
          .select()
          .eq('id', widget.orderId)
          .single();

      if (!mounted) return;

      setState(() {
        status = response['status'] as String? ?? 'Обработка';
        isLoading = false;
        errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Не удалось загрузить статус заказа';
      });
    }
  }

  void listenStatus() {
    channel = supabase
        .channel('order_status_${widget.orderId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.orderId,
          ),
          callback: (payload) {
            final newStatus = payload.newRecord['status'] as String?;
            if (!mounted || newStatus == null) return;

            setState(() {
              status = newStatus;
              isLoading = false;
              errorMessage = null;
            });
          },
        )
        .subscribe();
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
        title: Text('Заказ #${widget.orderId}'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(padding: const EdgeInsets.all(24), child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const CircularProgressIndicator();
    }

    if (errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 56),
          const SizedBox(height: 16),
          Text(errorMessage!),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: loadOrder, child: const Text('Повторить')),
        ],
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Текущий статус',
            style: TextStyle(color: Colors.white70, fontSize: 22),
          ),
          const SizedBox(height: 20),
          Text(
            status,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 28),
          OrderStatusProgress(status: status),
        ],
      ),
    );
  }
}
