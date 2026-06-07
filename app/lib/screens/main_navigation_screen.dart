import 'package:flutter/material.dart';

import '../cart/cart_screen.dart';
import '../cart/cart_service.dart';
import '../models/app_user.dart';
import 'home_screen.dart';
import 'orders_history_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final AppUser user;

  const MainNavigationScreen({super.key, required this.user});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final cart = CartService.instance;
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const OrdersHistoryScreen(),
      const CartScreen(),
      ProfileScreen(user: widget.user),
    ];

    return AnimatedBuilder(
      animation: cart,
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(index: currentIndex, children: screens),

          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.black,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white54,
            onTap: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Главная',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'Заказы',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: cart.itemCount > 0,
                  label: Text('${cart.itemCount}'),
                  child: const Icon(Icons.shopping_cart),
                ),
                label: 'Корзина',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Профиль',
              ),
            ],
          ),
        );
      },
    );
  }
}
