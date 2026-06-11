import 'package:flutter/material.dart';

import '../screens/order_status_screen.dart';
import '../services/order_service.dart';
import 'cart_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final orderService = OrderService();

  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final cart = CartService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Корзина'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,

      body: cart.items.isEmpty
          ? const Center(
              child: Text(
                'Корзина пуста',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];

                      return Card(
                        color: Colors.grey[900],
                        margin: const EdgeInsets.all(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.coffee.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                'Размер: ${item.size}',
                                style: const TextStyle(color: Colors.white70),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                item.toppings.isEmpty
                                    ? 'Допинги: Нет'
                                    : 'Допинги: ${item.toppings.join(", ")}',
                                style: const TextStyle(color: Colors.white70),
                              ),

                              const SizedBox(height: 12),

                              Text(
                                '${item.totalPrice.toStringAsFixed(0)} ₽',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Итого: ${cart.totalPrice.toStringAsFixed(0)} ₽',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  setState(() {
                                    isSubmitting = true;
                                  });

                                  try {
                                    final orderId = await orderService
                                        .createOrder(
                                          cart.items,
                                          cart.totalPrice,
                                        );

                                    cart.clear();

                                    if (!mounted) return;

                                    setState(() {
                                      isSubmitting = false;
                                    });

                                    if (!context.mounted) return;

                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            OrderStatusScreen(orderId: orderId),
                                      ),
                                    );
                                  } catch (_) {
                                    if (!mounted) return;

                                    setState(() {
                                      isSubmitting = false;
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Не удалось создать заказ',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Оплатить'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
