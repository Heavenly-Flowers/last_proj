import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  final supabase = Supabase.instance.client;

  List supportRequests = [];
  List profiles = [];
  List roles = [];
  List coffees = [];
  List toppings = [];

  bool isLoadingSupport = true;
  bool isLoadingUsers = true;
  bool isLoadingPrices = true;
  String? supportErrorMessage;
  String? usersErrorMessage;
  String? pricesErrorMessage;

  String? get currentUserId => supabase.auth.currentUser?.id;
  RealtimeChannel? pricesChannel;

  @override
  void initState() {
    super.initState();
    loadSupportRequests();
    loadUsers();
    loadPrices();
    listenPrices();
  }

  @override
  void dispose() {
    if (pricesChannel != null) {
      supabase.removeChannel(pricesChannel!);
    }

    super.dispose();
  }

  Future<void> loadSupportRequests() async {
    setState(() {
      isLoadingSupport = true;
    });

    try {
      final response = await supabase
          .from('support_requests')
          .select('id, user_id, email, message, status, created_at')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        supportRequests = response;
        supportErrorMessage = null;
        isLoadingSupport = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        supportErrorMessage = 'Не удалось загрузить обращения';
        isLoadingSupport = false;
      });
    }
  }

  Future<void> loadUsers() async {
    setState(() {
      isLoadingUsers = true;
    });

    try {
      final rolesResponse = await supabase
          .from('roles')
          .select('id, name')
          .order('id');

      final profilesResponse = await supabase
          .from('profiles')
          .select('user_id, email, full_name, phone, role_id, created_at')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        roles = rolesResponse;
        profiles = profilesResponse;
        usersErrorMessage = null;
        isLoadingUsers = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        usersErrorMessage = 'Не удалось загрузить пользователей';
        isLoadingUsers = false;
      });
    }
  }

  Future<void> loadPrices() async {
    setState(() {
      isLoadingPrices = true;
    });

    try {
      final coffeesResponse = await supabase
          .from('coffees')
          .select('id, title, price')
          .eq('is_active', true)
          .order('id');

      final toppingsResponse = await supabase
          .from('toppings')
          .select('id, name, price')
          .order('id');

      if (!mounted) return;

      setState(() {
        coffees = coffeesResponse;
        toppings = toppingsResponse;
        pricesErrorMessage = null;
        isLoadingPrices = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        pricesErrorMessage = 'Не удалось загрузить цены';
        isLoadingPrices = false;
      });
    }
  }

  void listenPrices() {
    pricesChannel = supabase
        .channel('admin_prices')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'coffees',
          callback: (_) {
            loadPrices();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'toppings',
          callback: (_) {
            loadPrices();
          },
        );

    pricesChannel!.subscribe();
  }

  Future<void> updatePrice({
    required String table,
    required int id,
    required double price,
  }) async {
    try {
      await supabase.from(table).update({'price': price}).eq('id', id);

      await loadPrices();
      showMessage('Цена обновлена');
    } catch (_) {
      showMessage('Не удалось обновить цену');
    }
  }

  Future<void> updateUserRole({
    required String userId,
    required int roleId,
  }) async {
    try {
      await supabase
          .from('profiles')
          .update({'role_id': roleId})
          .eq('user_id', userId);

      if (!mounted) return;

      setState(() {
        profiles = profiles.map((profileData) {
          final profile = profileData as Map<String, dynamic>;

          if (profile['user_id'] == userId) {
            return {...profile, 'role_id': roleId};
          }

          return profile;
        }).toList();
      });

      showMessage('Роль обновлена');
    } catch (_) {
      showMessage('Не удалось обновить роль');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Админ'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Жалобы'),
              Tab(text: 'Управление'),
              Tab(text: 'Цены'),
            ],
          ),
        ),
        body: TabBarView(
          children: [buildSupportTab(), buildUsersTab(), buildPricesTab()],
        ),
      ),
    );
  }

  Widget buildSupportTab() {
    if (isLoadingSupport) {
      return const Center(child: CircularProgressIndicator());
    }

    if (supportErrorMessage != null) {
      return Center(
        child: Text(
          supportErrorMessage!,
          style: const TextStyle(color: Colors.white, fontSize: 22),
        ),
      );
    }

    if (supportRequests.isEmpty) {
      return const Center(
        child: Text(
          'Обращений пока нет',
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadSupportRequests,
      child: ListView.builder(
        itemCount: supportRequests.length,
        itemBuilder: (context, index) {
          final request = supportRequests[index] as Map<String, dynamic>;

          return Card(
            color: Colors.grey[900],
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request['email'] ?? 'Без email',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Время: ${formatDate(request['created_at'])}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Статус: ${request['status']}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    request['message'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildUsersTab() {
    if (isLoadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (usersErrorMessage != null) {
      return Center(
        child: Text(
          usersErrorMessage!,
          style: const TextStyle(color: Colors.white, fontSize: 22),
        ),
      );
    }

    if (profiles.isEmpty) {
      return const Center(
        child: Text(
          'Пользователей пока нет',
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadUsers,
      child: ListView.builder(
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          final profile = profiles[index] as Map<String, dynamic>;
          final userId = profile['user_id'] as String;
          final roleId = profile['role_id'] as int?;
          final roleName = getRoleName(roleId);
          final isCurrentUser = userId == currentUserId;

          return Card(
            color: Colors.grey[900],
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  roleBadge(roleName),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile['email'] ?? userId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          profile['full_name'] ?? 'Имя не указано',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Регистрация: ${formatDate(profile['created_at'])}',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: roleId,
                    dropdownColor: Colors.grey[900],
                    disabledHint: Text(
                      roleName,
                      style: const TextStyle(color: Colors.white54),
                    ),
                    items: roles.map((roleData) {
                      final role = roleData as Map<String, dynamic>;

                      return DropdownMenuItem<int>(
                        value: role['id'] as int,
                        child: Text(role['name'] as String),
                      );
                    }).toList(),
                    onChanged: isCurrentUser
                        ? null
                        : (newRoleId) {
                            if (newRoleId == null || newRoleId == roleId) {
                              return;
                            }

                            updateUserRole(userId: userId, roleId: newRoleId);
                          },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildPricesTab() {
    if (isLoadingPrices) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pricesErrorMessage != null) {
      return Center(
        child: Text(
          pricesErrorMessage!,
          style: const TextStyle(color: Colors.white, fontSize: 22),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadPrices,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Кофе',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...coffees.map((coffeeData) {
            final coffee = coffeeData as Map<String, dynamic>;

            return priceCard(
              title: coffee['title'] as String,
              price: (coffee['price'] as num).toDouble(),
              onEdit: () {
                openPriceDialog(
                  title: coffee['title'] as String,
                  currentPrice: (coffee['price'] as num).toDouble(),
                  onSave: (price) {
                    updatePrice(
                      table: 'coffees',
                      id: coffee['id'] as int,
                      price: price,
                    );
                  },
                );
              },
            );
          }),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Допинги',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...toppings.map((toppingData) {
            final topping = toppingData as Map<String, dynamic>;

            return priceCard(
              title: topping['name'] as String,
              price: (topping['price'] as num).toDouble(),
              onEdit: () {
                openPriceDialog(
                  title: topping['name'] as String,
                  currentPrice: (topping['price'] as num).toDouble(),
                  onSave: (price) {
                    updatePrice(
                      table: 'toppings',
                      id: topping['id'] as int,
                      price: price,
                    );
                  },
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget priceCard({
    required String title,
    required double price,
    required VoidCallback onEdit,
  }) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${price.toStringAsFixed(0)} ₽',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit),
          color: Colors.white,
        ),
      ),
    );
  }

  void openPriceDialog({
    required String title,
    required double currentPrice,
    required ValueChanged<double> onSave,
  }) {
    final controller = TextEditingController(
      text: currentPrice.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Цена',
                suffixText: '₽',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final price = double.tryParse(
                  (value ?? '').replaceAll(',', '.').trim(),
                );

                if (price == null) {
                  return 'Введите число';
                }

                if (price < 0) {
                  return 'Цена не может быть отрицательной';
                }

                if (price > 100000) {
                  return 'Цена слишком большая';
                }

                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) {
                  return;
                }

                final price = double.parse(
                  controller.text.replaceAll(',', '.').trim(),
                );

                Navigator.of(dialogContext).pop();
                onSave(price);
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  Widget roleBadge(String roleName) {
    final isAdmin = roleName == 'admin';

    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isAdmin ? Colors.white : Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isAdmin ? 'админ' : 'польз.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isAdmin ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String getRoleName(int? roleId) {
    if (roleId == null) {
      return 'user';
    }

    final role = roles.cast<Map<String, dynamic>?>().firstWhere(
      (role) => role?['id'] == roleId,
      orElse: () => null,
    );

    return role?['name'] ?? 'user';
  }

  String formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();

    if (date == null) {
      return 'неизвестно';
    }

    return '${twoDigits(date.day)}.${twoDigits(date.month)}.${date.year} '
        '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }

  String twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}
