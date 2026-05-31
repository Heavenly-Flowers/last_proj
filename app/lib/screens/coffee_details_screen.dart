import 'package:flutter/material.dart';
import '../cart/cart_item.dart';
import '../cart/cart_service.dart';
import '../models/coffee.dart';


class CoffeeDetailsScreen extends StatefulWidget {
  final Coffee coffee;

  const CoffeeDetailsScreen({
    super.key,
    required this.coffee,
  });

  @override
  State<CoffeeDetailsScreen> createState() =>
      _CoffeeDetailsScreenState();
}

class _CoffeeDetailsScreenState
    extends State<CoffeeDetailsScreen> {

  String selectedSize = 'M';

  final List<String> selectedToppings = [];

  final List<String> toppings = [
    'Ванильный сироп',
    'Карамельный сироп',
    'Лесной орех',
    'Маршмеллоу',
    'Печеньки',
    'Корица',
  ];

  @override
  Widget build(BuildContext context) {
    final coffee = widget.coffee;

    return Scaffold(
      appBar: AppBar(
        title: Text(coffee.title),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Text(
                'Состав: ${coffee.description}',
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
              ),
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
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                sizeButton('S'),
                sizeButton('M'),
                sizeButton('L'),
              ],
            ),

            const SizedBox(height: 24),

            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Text(
                'Допинги',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            ...toppings.map(
              (topping) => CheckboxListTile(
                title: Text(
                  topping,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
                value: selectedToppings.contains(
                  topping,
                ),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedToppings.add(
                        topping,
                      );
                    } else {
                      selectedToppings.remove(
                        topping,
                      );
                    }
                  });
                },
              ),
            ),

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
                        toppings: selectedToppings,
                      );

                      CartService.instance.addItem(item);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Добавлено в корзину',
                          ),
                        ),
                      );
                  },
                  child: Text(
                    'Добавить в корзину • ${coffee.price.toStringAsFixed(0)} ₽',
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
    final isSelected =
        selectedSize == size;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected
                  ? Colors.white
                  : Colors.grey[900],
          foregroundColor:
              isSelected
                  ? Colors.black
                  : Colors.white,
        ),
        onPressed: () {
          setState(() {
            selectedSize = size;
          });
        },
        child: Text(size),
      ),
    );
  }
}