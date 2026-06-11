import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  final profileFormKey = GlobalKey<FormState>();
  final supportFormKey = GlobalKey<FormState>();
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

    if (profileFormKey.currentState?.validate() != true) {
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

    if (supportFormKey.currentState?.validate() != true) {
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

  String? validateName(String? value) {
    final name = value?.trim() ?? '';
    final nameRegex = RegExp(r"^[A-Za-zА-Яа-яЁё\s'-]+$");

    if (name.isEmpty) {
      return 'Введите имя';
    }

    if (name.length < 2) {
      return 'Имя должно быть не короче 2 символов';
    }

    if (name.length > 60) {
      return 'Имя должно быть не длиннее 60 символов';
    }

    if (!nameRegex.hasMatch(name)) {
      return 'Имя может содержать только буквы, пробел, дефис и апостроф';
    }

    return null;
  }

  String? validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    final phoneRegex = RegExp(r'^\+?[0-9\s()\-]{10,20}$');

    if (phone.isEmpty) {
      return 'Введите телефон';
    }

    if (!phoneRegex.hasMatch(phone) ||
        digitsOnly.length < 10 ||
        digitsOnly.length > 15) {
      return 'Введите корректный телефон';
    }

    return null;
  }

  String? validateSupportMessage(String? value) {
    final message = value?.trim() ?? '';

    if (message.isEmpty) {
      return 'Введите текст обращения';
    }

    if (message.length < 10) {
      return 'Опишите проблему минимум в 10 символах';
    }

    if (message.length > 1000) {
      return 'Обращение должно быть не длиннее 1000 символов';
    }

    return null;
  }

  void openSupportDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Написать в поддержку'),
          content: Form(
            key: supportFormKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: TextFormField(
              controller: supportController,
              minLines: 4,
              maxLines: 8,
              maxLength: 1000,
              validator: validateSupportMessage,
              decoration: const InputDecoration(
                labelText: 'Жалоба или претензия',
                border: OutlineInputBorder(),
              ),
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
          : Form(
              key: profileFormKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
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
                  TextFormField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    validator: validateName,
                    decoration: const InputDecoration(
                      labelText: 'Имя',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    validator: validatePhone,
                    onFieldSubmitted: (_) {
                      if (!isSaving) {
                        saveProfile();
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Телефон',
                      hintText: '+7 999 123-45-67',
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
            ),
    );
  }
}
