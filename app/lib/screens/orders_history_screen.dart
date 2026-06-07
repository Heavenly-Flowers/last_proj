import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/order_service.dart';
import '../widgets/order_status_progress.dart';
import 'order_status_screen.dart';

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  final _orderService = OrderService();
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _orders = [];
  RealtimeChannel? _ordersChannel;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _listenToOrders();
  }

  Future<void> _loadOrders({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final orders = await _orderService.getCurrentUserOrders();
      if (!mounted) return;

      setState(() {
        _orders = orders;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (_orders.isEmpty) {
          _errorMessage = 'Не удалось загрузить историю заказов';
        }
      });
    }
  }

  void _listenToOrders() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _ordersChannel = _supabase
        .channel('orders_history_${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: _handleOrderChange,
        )
        .subscribe();
  }

  void _handleOrderChange(PostgresChangePayload payload) {
    if (!mounted) return;

    if (payload.eventType == PostgresChangeEvent.delete) {
      final deletedId = payload.oldRecord['id'];
      setState(() {
        _orders.removeWhere(
          (order) => order['id'].toString() == deletedId.toString(),
        );
      });
      return;
    }

    final changedOrder = payload.newRecord;
    if (changedOrder.isEmpty) return;

    setState(() {
      final index = _orders.indexWhere(
        (order) => order['id'].toString() == changedOrder['id'].toString(),
      );

      if (index == -1) {
        _orders.insert(0, Map<String, dynamic>.from(changedOrder));
      } else {
        _orders[index] = {..._orders[index], ...changedOrder};
      }

      _orders.sort(_compareOrdersByDate);
      _isLoading = false;
      _errorMessage = null;
    });
  }

  int _compareOrdersByDate(
    Map<String, dynamic> first,
    Map<String, dynamic> second,
  ) {
    final firstDate = DateTime.tryParse(first['created_at'] as String? ?? '');
    final secondDate = DateTime.tryParse(second['created_at'] as String? ?? '');

    if (firstDate != null && secondDate != null) {
      return secondDate.compareTo(firstDate);
    }

    final firstId = (first['id'] as num?)?.toInt() ?? 0;
    final secondId = (second['id'] as num?)?.toInt() ?? 0;
    return secondId.compareTo(firstId);
  }

  Future<void> _openOrderStatus(Map<String, dynamic> order) async {
    final orderId = (order['id'] as num).toInt();

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderStatusScreen(orderId: orderId)),
    );

    if (!mounted) return;
    await _loadOrders(showLoading: false);
  }

  @override
  void dispose() {
    if (_ordersChannel != null) {
      _supabase.removeChannel(_ordersChannel!);
    }
    super.dispose();
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
      body: RefreshIndicator(
        onRefresh: () => _loadOrders(showLoading: false),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 420,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 52),
                  const SizedBox(height: 12),
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadOrders,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 420,
            child: Center(
              child: Text(
                'Заказов пока нет',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];

        return OrderHistoryCard(
          order: order,
          onTap: () => _openOrderStatus(order),
        );
      },
    );
  }
}

class OrderHistoryCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;

  const OrderHistoryCard({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = order['items'] as List<dynamic>? ?? [];
    final status = order['status'] as String? ?? 'Обработка';

    return Card(
      color: Colors.grey[900],
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.all(12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Заказ #${order['id']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white54),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              OrderStatusProgress(status: status),
              const SizedBox(height: 14),
              Text(
                'Сумма: ${order['total_price']} ₽',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
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
              ...items.map((rawItem) {
                final item = Map<String, dynamic>.from(rawItem as Map);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${item['coffee']} (${item['size']})',
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              }),
              const SizedBox(height: 8),
              const Text(
                'Нажмите, чтобы открыть статус заказа',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
