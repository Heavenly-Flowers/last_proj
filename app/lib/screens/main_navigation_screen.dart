import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../cart/cart_screen.dart';
import 'admin_support_screen.dart';
import 'home_screen.dart';
import 'orders_history_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final supabase = Supabase.instance.client;

  int currentIndex = 0;
  bool isLoadingRole = true;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    loadUserRole();
  }

  Future<void> loadUserRole() async {
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      setState(() {
        isLoadingRole = false;
      });
      return;
    }

    try {
      final profile = await supabase
          .from('profiles')
          .select('role_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (!mounted) return;

      final roleId = profile?['role_id'];

      if (roleId == null) {
        setState(() {
          isLoadingRole = false;
        });
        return;
      }

      final role = await supabase
          .from('roles')
          .select('name')
          .eq('id', roleId)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        isAdmin = role?['name'] == 'admin';
        isLoadingRole = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoadingRole = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const OrdersHistoryScreen(),
      const CartScreen(),
      const ProfileScreen(),
      if (isAdmin) const AdminSupportScreen(),
    ];

    final items = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
      const BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Заказы'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.shopping_cart),
        label: 'Корзина',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Админ',
        ),
    ];

    if (currentIndex >= screens.length) {
      currentIndex = screens.length - 1;
    }

    return Scaffold(
      body: isLoadingRole
          ? const Center(child: CircularProgressIndicator())
          : screens[currentIndex],
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
        items: items,
      ),
    );
  }
}
