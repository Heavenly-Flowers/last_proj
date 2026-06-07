import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final AppUser user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    setState(() {
      _isSigningOut = true;
    });

    try {
      await _authService.signOut();
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 46,
            backgroundColor: Colors.white,
            child: Icon(
              user.isAdmin ? Icons.admin_panel_settings : Icons.person,
              size: 52,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            user.fullName.isEmpty ? 'Пользователь' : user.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Card(
            color: Colors.grey[900],
            child: ListTile(
              leading: Icon(
                user.isAdmin ? Icons.verified_user : Icons.person_outline,
              ),
              title: const Text('Роль'),
              subtitle: Text(user.role.displayName),
            ),
          ),
          if (user.isAdmin)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Card(
                color: Color(0xFF2A2100),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Администратор имеет доступ к управлению всеми заказами '
                    'через административное приложение.',
                  ),
                ),
              ),
            ),
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _isSigningOut ? null : _signOut,
              icon: _isSigningOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout),
              label: const Text('Выйти из аккаунта'),
            ),
          ),
        ],
      ),
    );
  }
}
