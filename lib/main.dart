import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// This address connects an Android emulator to your laptop.
const backendUrl = 'http://127.0.0.1:8000';

void main() {
  runApp(const ArtisanApp());
}

// Fetch the product list from Python.
Future<List<dynamic>> fetchProducts() async {
  final url = Uri.parse('$backendUrl/products');

  final response = await http.get(url).timeout(
    const Duration(seconds: 15),
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Backend returned error ${response.statusCode}',
    );
  }

  // Convert JSON text into a Dart list.
  return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
}

Future<void> createProduct({
  required String name,
  required String material,
  required int pricePaise,
  required int quantity,
}) async {
  final response = await http.post(
    Uri.parse('$backendUrl/products'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'name': name,
      'material': material,
      'price_paise': pricePaise,
      'quantity': quantity,
    }),
  ).timeout(const Duration(seconds: 15));

  if (response.statusCode != 201) {
    throw Exception(
      'Could not add product: ${response.statusCode}\n'
          '${response.body}',
    );
  }
}
class ArtisanApp extends StatelessWidget {
  const ArtisanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Artisan App',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const ProductsPage(),
    );
  }
}

// This screen can change as data loads or refreshes.
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late Future<List<dynamic>> productsFuture;

  @override
  void initState() {
    super.initState();

    // Fetch once when the screen is created.
    productsFuture = fetchProducts();
  }

  void refreshProducts() {
    setState(() {
      productsFuture = fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        actions: [
          IconButton(
            onPressed: refreshProducts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh products',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
        onPressed: () async {
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddProductPage(),
            ),
          );

          if (!mounted) return;

          if (saved == true) {
            refreshProducts();
          }
        },
      ),
      body: FutureBuilder<List<dynamic>>(
        future: productsFuture,
        builder: (context, snapshot) {
          // State 1: Still waiting for the backend.
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // State 2: The request failed.
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SelectableText(
                      'Could not load products.\n'
                          'Backend: $backendUrl\n'
                          'Error: ${snapshot.error}',
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: refreshProducts,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(
              child: Text('No products yet'),
            );
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final price =
                  (product['price_paise'] as num) / 100;

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.shopping_basket,
                    color: Colors.teal,
                  ),
                  title: Text(product['name']),
                  subtitle: Text(
                    'Material: ${product['material']}\n'
                        'Price: ₹${price.toStringAsFixed(2)}\n'
                        'Available: ${product['quantity']}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final formKey = GlobalKey<FormState>();

  // Controllers let us read what the user types.
  final nameController = TextEditingController();
  final materialController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();

  bool saving = false;

  Future<void> saveProduct() async {
    // Stop if any field contains invalid input.
    if (!formKey.currentState!.validate()) return;

    setState(() {
      saving = true;
    });

    try {
      // Convert rupees to whole paise without decimal arithmetic.
      final priceParts = priceController.text.trim().split('.');
      final rupees = int.parse(priceParts[0]);
      final paise = priceParts.length == 2
          ? int.parse(priceParts[1].padRight(2, '0'))
          : 0;

      await createProduct(
        name: nameController.text.trim(),
        material: materialController.text.trim(),
        pricePaise: rupees * 100 + paise,
        quantity: int.parse(quantityController.text.trim()),
      );

      if (!mounted) return;

      // Close the form and tell the previous screen it was saved.
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not confirm the save: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    materialController.dispose();
    priceController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !saving,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add product'),
        ),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: nameController,
                enabled: !saving,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Product name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: materialController,
                enabled: !saving,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Material',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the material';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: priceController,
                enabled: !saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Price in rupees',
                  hintText: '450 or 450.50',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) {
                    return 'Enter a valid price, such as 450.50';
                  }

                  final price = double.tryParse(text);
                  if (price == null ||
                      !price.isFinite ||
                      price > 10000000) {
                    return 'Enter a price up to ₹1,00,00,000';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: quantityController,
                enabled: !saving,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Available quantity',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final quantity = int.tryParse(value?.trim() ?? '');

                  if (quantity == null ||
                      quantity < 0 ||
                      quantity > 1000000) {
                    return 'Enter a whole number from 0 to 1000000';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 24),

              FilledButton(
                onPressed: saving ? null : saveProduct,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    saving ? 'Saving...' : 'Save product',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}