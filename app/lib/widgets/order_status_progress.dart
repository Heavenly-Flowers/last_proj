import 'package:flutter/material.dart';

import '../models/order_status.dart';

class OrderStatusProgress extends StatelessWidget {
  final String status;
  final bool showNextStatus;

  const OrderStatusProgress({
    super.key,
    required this.status,
    this.showNextStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    final statusIndex = OrderStatuses.indexOf(status);
    final nextStatus = OrderStatuses.nextAfter(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Этап ${statusIndex + 1} из ${OrderStatuses.values.length}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              '${(OrderStatuses.progressOf(status) * 100).round()}%',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: OrderStatuses.progressOf(status),
            backgroundColor: Colors.white12,
          ),
        ),
        if (showNextStatus && nextStatus != null) ...[
          const SizedBox(height: 8),
          Text(
            'Следующий статус: $nextStatus',
            style: const TextStyle(color: Colors.white54),
          ),
        ],
        if (showNextStatus && nextStatus == null) ...[
          const SizedBox(height: 8),
          const Text(
            'Заказ завершён',
            style: TextStyle(color: Colors.greenAccent),
          ),
        ],
      ],
    );
  }
}
