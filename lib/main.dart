import 'package:flutter/material.dart';
import 'package:artesian/screens/artisan/products_page.dart';
import 'package:artesian/theme/app_theme.dart';

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
      theme: AppTheme.light(),
      home: const ProductsPage(),
    );
  }
}
