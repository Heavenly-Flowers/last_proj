import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/coffee.dart';

class CoffeeService {
  final supabase = Supabase.instance.client;

  Future<List<Coffee>> getCoffees() async {
    final response = await supabase
        .from('coffees')
        .select()
        .eq('is_active', true)
        .order('id');

    return (response as List).map((json) => Coffee.fromJson(json)).toList();
  }

  Future<void> updateCoffeePrice({
    required int coffeeId,
    required double price,
  }) async {
    await supabase.from('coffees').update({'price': price}).eq('id', coffeeId);
  }
}
