import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/coffee.dart';

class CoffeeService {
  final supabase = Supabase.instance.client;

  Future<List<Coffee>> getCoffees() async {
    final response = await supabase
        .from('coffees')
        .select();

    return (response as List)
        .map((json) => Coffee.fromJson(json))
        .toList();
  }
}