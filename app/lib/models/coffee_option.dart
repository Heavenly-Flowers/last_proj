class CoffeeSizeOption {
  final String code;
  final String name;
  final double extraPrice;

  const CoffeeSizeOption({
    required this.code,
    required this.name,
    required this.extraPrice,
  });
}

class ToppingOption {
  final String name;
  final double price;

  const ToppingOption({required this.name, required this.price});
}

abstract final class CoffeeOptions {
  static const sizes = [
    CoffeeSizeOption(code: 'S', name: 'Маленький', extraPrice: 0),
    CoffeeSizeOption(code: 'M', name: 'Средний', extraPrice: 30),
    CoffeeSizeOption(code: 'L', name: 'Большой', extraPrice: 60),
  ];

  static const toppings = [
    ToppingOption(name: 'Ванильный сироп', price: 20),
    ToppingOption(name: 'Карамельный сироп', price: 20),
    ToppingOption(name: 'Лесной орех', price: 30),
    ToppingOption(name: 'Маршмеллоу', price: 30),
    ToppingOption(name: 'Печеньки', price: 25),
    ToppingOption(name: 'Корица', price: 10),
  ];
}
