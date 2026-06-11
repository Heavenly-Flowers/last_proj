import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final supportController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  bool isSendingSupportRequest = false;

  String get email => supabase.auth.currentUser?.email ?? '';
  String? get userId => supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    supportController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    final id = userId;

    if (id == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await supabase
          .from('profiles')
          .select('full_name, phone')
          .eq('user_id', id)
          .maybeSingle();

      if (!mounted) return;

      nameController.text = response?['full_name'] ?? '';
      phoneController.text = response?['phone'] ?? '';
    } catch (_) {
      showMessage('Не удалось загрузить профиль');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> saveProfile() async {
    final id = userId;

    if (id == null) {
      showMessage('Пользователь не авторизован');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await supabase
          .from('profiles')
          .update({
            'full_name': nameController.text.trim(),
            'phone': phoneController.text.trim(),
          })
          .eq('user_id', id);

      showMessage('Профиль сохранен');
    } catch (_) {
      showMessage('Не удалось сохранить профиль');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> sendSupportRequest() async {
    final id = userId;
    final message = supportController.text.trim();

    if (id == null) {
      showMessage('Пользователь не авторизован');
      return;
    }

    if (message.isEmpty) {
      showMessage('Введите текст обращения');
      return;
    }

    setState(() {
      isSendingSupportRequest = true;
    });

    try {
      await supabase.from('support_requests').insert({
        'user_id': id,
        'email': email,
        'message': message,
      });

      supportController.clear();

      if (!mounted) return;
      Navigator.of(context).pop();
      showMessage('Обращение отправлено');
    } catch (_) {
      showMessage('Не удалось отправить обращение');
    } finally {
      if (mounted) {
        setState(() {
          isSendingSupportRequest = false;
        });
      }
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void openSupportDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Написать в поддержку'),
          content: TextField(
            controller: supportController,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Жалоба или претензия',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSendingSupportRequest
                  ? null
                  : () {
                      supportController.clear();
                      Navigator.of(dialogContext).pop();
                    },
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: isSendingSupportRequest ? null : sendSupportRequest,
              child: isSendingSupportRequest
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Отправить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Профиль'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  readOnly: true,
                  initialValue: email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Имя',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Телефон',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : saveProfile,
                    child: isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Сохранить'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: openSupportDialog,
                    child: const Text('Написать в поддержку'),
                  ),
                ),
              ],
            ),
    );
  }
}
