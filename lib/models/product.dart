class Product {
  final int id;
  final String name;
  final String material;
  final int pricePaise;
  final int quantity;
  final String? photoPath;
  final String description;
  final String artisan;
  final bool published;

  Product({
    required this.id,
    required this.name,
    required this.material,
    required this.pricePaise,
    required this.quantity,
    this.photoPath,
    required this.description,
    required this.artisan,
    required this.published,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      material: json['material'] as String,
      pricePaise: json['price_paise'] as int,
      quantity: json['quantity'] as int,
      photoPath: json['photo_path'] as String?,
      description: json['description']?.toString() ?? '',
      artisan: json['artisan']?.toString() ?? 'Artisan Studio',
      published: json['published'] == 1 || json['published'] == true,
    );
  }
}
