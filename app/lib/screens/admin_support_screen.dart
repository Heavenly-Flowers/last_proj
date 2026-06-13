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

  bool isLoadingSupport = true;
  bool isLoadingUsers = true;
  String? supportErrorMessage;
  String? usersErrorMessage;

  String? get currentUserId => supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    loadSupportRequests();
    loadUsers();
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
      length: 2,
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
            ],
          ),
        ),
        body: TabBarView(children: [buildSupportTab(), buildUsersTab()]),
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
