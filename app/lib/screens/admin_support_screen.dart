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
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadSupportRequests();
  }

  Future<void> loadSupportRequests() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await supabase
          .from('support_requests')
          .select('id, user_id, email, message, status, created_at')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        supportRequests = response;
        errorMessage = null;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Не удалось загрузить обращения';
        isLoading = false;
      });
    }
  }

  Future<void> refresh() async {
    await loadSupportRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Админ'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 22),
              ),
            )
          : supportRequests.isEmpty
          ? const Center(
              child: Text(
                'Обращений пока нет',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
            )
          : RefreshIndicator(
              onRefresh: refresh,
              child: ListView.builder(
                itemCount: supportRequests.length,
                itemBuilder: (context, index) {
                  final request =
                      supportRequests[index] as Map<String, dynamic>;

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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
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
