import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../cart/cart_item.dart';
import '../cart/cart_service.dart';
import '../models/coffee.dart';

class CoffeeDetailsScreen extends StatefulWidget {
  final Coffee coffee;

  const CoffeeDetailsScreen({super.key, required this.coffee});

  @override
  State<CoffeeDetailsScreen> createState() => _CoffeeDetailsScreenState();
}

class _CoffeeDetailsScreenState extends State<CoffeeDetailsScreen> {
  final supabase = Supabase.instance.client;

  String selectedSize = 'M';

  final List<String> selectedToppings = [];
  List toppings = [];
  bool isLoadingToppings = true;
  RealtimeChannel? channel;

  static const Map<String, double> sizePrices = {'S': 0, 'M': 30, 'L': 60};

  @override
  void initState() {
    super.initState();
    loadToppings();
    listenToppingPrices();
  }

  @override
  void dispose() {
    if (channel != null) {
      supabase.removeChannel(channel!);
    }

    super.dispose();
  }

  double get totalPrice {
    final sizePrice = sizePrices[selectedSize] ?? 0;
    final toppingsPrice = selectedToppings.fold<double>(
      0,
      (sum, topping) => sum + getToppingPrice(topping),
    );

    return widget.coffee.price + sizePrice + toppingsPrice;
  }

  void listenToppingPrices() {
    channel = supabase
        .channel('coffee_details_toppings')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'toppings',
          callback: (_) {
            loadToppings();
          },
        );

    channel!.subscribe();
  }

  Future<void> loadToppings() async {
    try {
      final response = await supabase
          .from('toppings')
          .select('id, name, price')
          .order('id');

      if (!mounted) return;

      setState(() {
        toppings = response;
        isLoadingToppings = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoadingToppings = false;
      });
    }
  }

  double getToppingPrice(String name) {
    final topping = toppings.cast<Map<String, dynamic>?>().firstWhere(
      (topping) => topping?['name'] == name,
      orElse: () => null,
    );

    return ((topping?['price'] ?? 20) as num).toDouble();
  }

  Map<String, double> get selectedToppingPrices {
    return {
      for (final topping in selectedToppings) topping: getToppingPrice(topping),
    };
  }

  @override
  Widget build(BuildContext context) {
    final coffee = widget.coffee;

    return Scaffold(
      appBar: AppBar(title: Text(coffee.title), backgroundColor: Colors.black),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              coffee.imageUrl,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                coffee.description,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Состав: ${coffee.description}',
                style: const TextStyle(color: Colors.white70),
              ),
            ),

            const SizedBox(height: 24),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Размер',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [sizeButton('S'), sizeButton('M'), sizeButton('L')],
            ),

            const SizedBox(height: 24),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Допинги',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (isLoadingToppings)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ...toppings.map((toppingData) {
                final topping = toppingData as Map<String, dynamic>;
                final name = topping['name'] as String;
                final price = (topping['price'] as num).toDouble();

                return CheckboxListTile(
                  title: Text(
                    '$name +${price.toStringAsFixed(0)} ₽',
                    style: const TextStyle(color: Colors.white),
                  ),
                  value: selectedToppings.contains(name),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedToppings.add(name);
                      } else {
                        selectedToppings.remove(name);
                      }
                    });
                  },
                );
              }),

            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    final item = CartItem(
                      coffee: coffee,
                      size: selectedSize,
                      toppings: List.of(selectedToppings),
                      toppingPrices: selectedToppingPrices,
                    );

                    CartService.instance.addItem(item);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Добавлено в корзину')),
                    );
                  },
                  child: Text(
                    'Добавить в корзину • ${totalPrice.toStringAsFixed(0)} ₽',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget sizeButton(String size) {
    final isSelected = selectedSize == size;
    final price = sizePrices[size] ?? 0;
    final priceText = price == 0 ? '+0 ₽' : '+${price.toStringAsFixed(0)} ₽';

    return Padding(
      padding: const EdgeInsets.all(8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.white : Colors.grey[900],
          foregroundColor: isSelected ? Colors.black : Colors.white,
        ),
        onPressed: () {
          setState(() {
            selectedSize = size;
          });
        },
        child: Text('$size $priceText'),
      ),
    );
  }
}
