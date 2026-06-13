import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/coffee.dart';
import '../services/coffee_service.dart';
import 'coffee_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  final coffeeService = CoffeeService();

  late Future<List<Coffee>> coffeesFuture;
  RealtimeChannel? channel;

  @override
  void initState() {
    super.initState();
    coffeesFuture = coffeeService.getCoffees();
    listenCoffeePrices();
  }

  @override
  void dispose() {
    if (channel != null) {
      supabase.removeChannel(channel!);
    }

    super.dispose();
  }

  Future<void> refreshCoffees() async {
    setState(() {
      coffeesFuture = coffeeService.getCoffees();
    });

    await coffeesFuture;
  }

  void listenCoffeePrices() {
    channel = supabase
        .channel('home_coffees')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'coffees',
          callback: (_) {
            if (!mounted) return;

            setState(() {
              coffeesFuture = coffeeService.getCoffees();
            });
          },
        );

    channel!.subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Зерновуха'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Coffee>>(
        future: coffeesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Не удалось загрузить меню',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
            );
          }

          final coffees = snapshot.data ?? [];

          if (coffees.isEmpty) {
            return const Center(
              child: Text(
                'Меню пока пустое',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: refreshCoffees,
            child: ListView.builder(
              itemCount: coffees.length,
              itemBuilder: (context, index) {
                final coffee = coffees[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CoffeeDetailsScreen(coffee: coffee),
                      ),
                    );
                  },
                  child: Card(
                    color: Colors.grey[900],
                    margin: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
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
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                coffee.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
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
                                  fontWeight: FontWeight.bold,
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
        },
      ),
    );
  }
}
