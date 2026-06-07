import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';

class RegistrationResult {
  final bool requiresEmailConfirmation;

  const RegistrationResult({required this.requiresEmailConfirmation});
}

class AuthService {
  SupabaseClient get _supabase => Supabase.instance.client;

  User? get currentAuthUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<RegistrationResult> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
    );

    if (response.user == null) {
      throw const AuthException('Не удалось создать пользователя');
    }

    return RegistrationResult(
      requiresEmailConfirmation: response.session == null,
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AppUser> getCurrentProfile() async {
    final authUser = currentAuthUser;

    if (authUser == null) {
      throw const AuthException('Пользователь не авторизован');
    }

    final existingProfile = await _supabase
        .from('profiles')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();

    if (existingProfile != null) {
      return AppUser.fromJson(existingProfile);
    }

    final profile = await _supabase
        .from('profiles')
        .insert({
          'id': authUser.id,
          'email': authUser.email ?? '',
          'full_name': authUser.userMetadata?['full_name'] ?? '',
          'role': 'user',
        })
        .select()
        .single();

    return AppUser.fromJson(profile);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
