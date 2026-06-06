import 'package:flutter/material.dart';

import '../cart/cart_screen.dart';
import 'home_screen.dart';
import 'orders_history_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen> {

  int currentIndex = 0;

  final screens = [
    const HomeScreen(),
    const OrdersHistoryScreen(),
    const CartScreen(),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: screens[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,

        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,

        onTap: (index) {

          setState(() {
            currentIndex = index;
          });
        },

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Заказы',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Корзина',
          ),
        ],
      ),
    );
  }
}