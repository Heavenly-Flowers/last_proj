import 'package:flutter/material.dart';

import '../screens/order_status_screen.dart';
import '../services/order_service.dart';
import 'cart_item.dart';
import 'cart_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final orderService = OrderService();
  final cart = CartService.instance;

  bool isSubmitting = false;

  Future<void> createOrder() async {
    final items = List<CartItem>.from(cart.items);
    final totalPrice = cart.totalPrice;

    setState(() {
      isSubmitting = true;
    });

    try {
      final orderId = await orderService.createOrder(items, totalPrice);

      if (!mounted) return;

      cart.clear();
      setState(() {
        isSubmitting = false;
      });

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderStatusScreen(orderId: orderId)),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось оформить заказ. Повторите попытку.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Корзина'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: cart,
        builder: (context, _) {
          if (cart.isEmpty) {
            return const Center(
              child: Text(
                'Корзина пуста',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cart.itemCount,
                  itemBuilder: (context, index) {
                    return cartItemCard(cart.items[index], index);
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Итого: '
                        '${cart.totalPrice.toStringAsFixed(0)} ₽',
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
                          onPressed: isSubmitting ? null : createOrder,
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Оформить заказ'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget cartItemCard(CartItem item, int index) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.coffee.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Удалить из корзины',
                  onPressed: () => cart.removeAt(index),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            priceRow('Базовая цена', item.coffee.price),
            priceRow(
              'Размер ${item.size.code}',
              item.size.extraPrice,
              showPlus: true,
            ),
            if (item.toppings.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Без топпингов',
                  style: TextStyle(color: Colors.white54),
                ),
              )
            else
              ...item.toppings.map(
                (topping) =>
                    priceRow(topping.name, topping.price, showPlus: true),
              ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Стоимость',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${item.totalPrice.toStringAsFixed(0)} ₽',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget priceRow(String label, double price, {bool showPlus = false}) {
    final prefix = showPlus && price > 0 ? '+' : '';

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Text(
            '$prefix${price.toStringAsFixed(0)} ₽',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
