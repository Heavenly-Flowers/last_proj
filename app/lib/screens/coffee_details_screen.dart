import 'package:flutter/material.dart';

import '../cart/cart_item.dart';
import '../cart/cart_service.dart';
import '../models/coffee.dart';
import '../models/coffee_option.dart';

class CoffeeDetailsScreen extends StatefulWidget {
  final Coffee coffee;

  const CoffeeDetailsScreen({super.key, required this.coffee});

  @override
  State<CoffeeDetailsScreen> createState() => _CoffeeDetailsScreenState();
}

class _CoffeeDetailsScreenState extends State<CoffeeDetailsScreen> {
  CoffeeSizeOption selectedSize = CoffeeOptions.sizes[1];
  final List<ToppingOption> selectedToppings = [];

  double get selectedToppingsPrice {
    return selectedToppings.fold(0, (sum, topping) => sum + topping.price);
  }

  double get currentPrice {
    return widget.coffee.price +
        selectedSize.extraPrice +
        selectedToppingsPrice;
  }

  void addToCart() {
    final item = CartItem(
      coffee: widget.coffee,
      size: selectedSize,
      toppings: selectedToppings,
    );

    CartService.instance.addItem(item);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${widget.coffee.title} добавлен в корзину')),
      );
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
              errorBuilder: (_, _, _) {
                return const SizedBox(
                  height: 300,
                  child: Center(
                    child: Icon(
                      Icons.local_cafe,
                      size: 72,
                      color: Colors.white54,
                    ),
                  ),
                );
              },
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
                'Базовая цена: ${coffee.price.toStringAsFixed(0)} ₽',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
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
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: CoffeeOptions.sizes.map((size) {
                  return Expanded(child: sizeButton(size));
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Топпинги',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...CoffeeOptions.toppings.map(
              (topping) => CheckboxListTile(
                title: Text(
                  topping.name,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '+${topping.price.toStringAsFixed(0)} ₽',
                  style: const TextStyle(color: Colors.white54),
                ),
                value: selectedToppings.contains(topping),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedToppings.add(topping);
                    } else {
                      selectedToppings.remove(topping);
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
                  onPressed: addToCart,
                  child: Text(
                    'Добавить в корзину • '
                    '${currentPrice.toStringAsFixed(0)} ₽',
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

  Widget sizeButton(CoffeeSizeOption size) {
    final isSelected = selectedSize == size;
    final priceLabel = size.extraPrice == 0
        ? 'без доплаты'
        : '+${size.extraPrice.toStringAsFixed(0)} ₽';

    return Padding(
      padding: const EdgeInsets.all(6),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          backgroundColor: isSelected ? Colors.white : Colors.grey[900],
          foregroundColor: isSelected ? Colors.black : Colors.white,
        ),
        onPressed: () {
          setState(() {
            selectedSize = size;
          });
        },
        child: Column(
          children: [
            Text(
              size.code,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(priceLabel, maxLines: 1, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
