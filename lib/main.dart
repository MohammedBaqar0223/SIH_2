import 'package:flutter/material.dart';
import 'package:artesian/screens/artisan/products_page.dart';

export 'package:artesian/services/product_service.dart';
export 'package:artesian/screens/artisan/pricing_assistant_page.dart';

void main() {
  runApp(const ArtisanApp());
}

class ArtisanApp extends StatelessWidget {
  const ArtisanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Artisan App',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const ProductsPage(),
    );
  }
}
