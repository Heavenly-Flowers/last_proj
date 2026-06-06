import 'package:flutter/material.dart';

import '../models/coffee.dart';
import 'coffee_details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final coffees = [

      Coffee(
        title: 'Эспрессо',
        description:
            'Крепкий классический кофе',
        price: 150,
        imageUrl:
            'https://images.unsplash.com/photo-1510707577719-ae7c14805e3a',
      ),

      Coffee(
        title: 'Капучино',
        description:
            'Кофе с молочной пенкой',
        price: 220,
        imageUrl:
            'https://images.unsplash.com/photo-1509042239860-f550ce710b93',
      ),

      Coffee(
        title: 'Латте',
        description:
            'Нежный молочный кофе',
        price: 240,
        imageUrl:
            'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085',
      ),

      Coffee(
        title: 'Американо',
        description:
            'Разбавленный эспрессо',
        price: 180,
        imageUrl:
            'https://images.unsplash.com/photo-1498804103079-a6351b050096',
      ),

      Coffee(
        title: 'Раф',
        description:
            'Сливочный сладкий кофе',
        price: 270,
        imageUrl:
            'https://images.unsplash.com/photo-1511920170033-f8396924c348',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text('Зерновуха'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),

      body: ListView.builder(
        itemCount: coffees.length,
        itemBuilder: (context, index) {

          final coffee = coffees[index];

          return GestureDetector(
            onTap: () {

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CoffeeDetailsScreen(
                    coffee: coffee,
                  ),
                ),
              );
            },

            child: Card(
              color: Colors.grey[900],
              margin: const EdgeInsets.all(12),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),

                    child: Image.network(
                      coffee.imageUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                  Padding(
                    padding:
                        const EdgeInsets.all(16),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        Text(
                          coffee.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          coffee.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          '${coffee.price.toStringAsFixed(0)} ₽',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}