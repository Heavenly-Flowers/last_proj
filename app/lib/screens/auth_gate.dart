import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'main_navigation_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();

  StreamSubscription<AuthState>? _authSubscription;
  User? _authUser;
  AppUser? _profile;
  Object? _profileError;
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    _authUser = _authService.currentAuthUser;
    _authSubscription = _authService.authStateChanges.listen((state) {
      _handleAuthUser(state.session?.user);
    });

    if (_authUser != null) {
      _loadProfile();
    }
  }

  void _handleAuthUser(User? user) {
    if (!mounted) return;

    if (user == null) {
      setState(() {
        _authUser = null;
        _profile = null;
        _profileError = null;
        _isLoadingProfile = false;
      });
      return;
    }

    final shouldReload = _authUser?.id != user.id || _profile == null;
    _authUser = user;

    if (shouldReload) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _profileError = null;
    });

    try {
      final profile = await _authService.getCurrentProfile();
      if (!mounted || _authUser?.id != profile.id) return;

      setState(() {
        _profile = profile;
        _isLoadingProfile = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _profileError = error;
        _isLoadingProfile = false;
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_authUser == null) {
      return const AuthScreen();
    }

    if (_isLoadingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_profileError != null || _profile == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'Не удалось загрузить профиль',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Проверьте, что SQL-схема авторизации применена в Supabase.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadProfile,
                  child: const Text('Повторить'),
                ),
                TextButton(
                  onPressed: _authService.signOut,
                  child: const Text('Выйти'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MainNavigationScreen(user: _profile!);
  }
}
