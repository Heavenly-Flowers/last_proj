class Coffee {
  final int id;
  final String title;
  final String description;
  final String composition;
  final String imageUrl;
  final double price;

  Coffee({
    required this.id,
    required this.title,
    required this.description,
    required this.composition,
    required this.imageUrl,
    required this.price,
  });

  factory Coffee.fromJson(Map<String, dynamic> json) {
    return Coffee(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      composition: json['composition'],
      imageUrl: json['image_url'],
      price: (json['price'] as num).toDouble(),
    );
  }
}