import 'package:flutter/material.dart';
import 'package:artesian/services/product_service.dart';
import 'package:artesian/screens/artisan/add_product_page.dart';
import 'package:artesian/screens/customer/customer_catalog_page.dart';

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
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CustomerCatalogPage()),
              );
            },
            icon: const Icon(Icons.storefront),
            tooltip: 'Open marketplace',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
        onPressed: () async {
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const AddProductPage()),
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
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

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
            return const Center(child: Text('No products yet'));
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final price = (product['price_paise'] as num) / 100;
              final photoUrl = productPhotoUrl(product);
              final published =
                  product['published'] == 1 || product['published'] == true;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final saved = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddProductPage(
                          product: Map<String, dynamic>.from(product),
                        ),
                      ),
                    );
                    if (!mounted) return;
                    if (saved == true) {
                      refreshProducts();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 72,
                            height: 72,
                            child: photoUrl.isEmpty
                                ? Container(
                                    width: 72,
                                    height: 72,
                                    color: Colors.teal.shade50,
                                    child: const Icon(
                                      Icons.shopping_basket,
                                      color: Colors.teal,
                                      size: 40,
                                    ),
                                  )
                                : Image.network(
                                    photoUrl,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 72,
                                        height: 72,
                                        color: Colors.teal.shade50,
                                        child: const Icon(
                                          Icons.shopping_basket,
                                          color: Colors.teal,
                                          size: 40,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Material: ${product['material']}',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Price: ₹${price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Available: ${product['quantity']}',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 6),
                              if (published)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Published',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              else
                                FilledButton.tonalIcon(
                                  onPressed: () async {
                                    try {
                                      await publishProduct(
                                        (product['id'] as num).toInt(),
                                      );
                                      if (!mounted) return;
                                      refreshProducts();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Published to marketplace',
                                          ),
                                        ),
                                      );
                                    } catch (error) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Could not publish: $error',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.public),
                                  label: const Text('Publish to marketplace'),
                                ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.edit, color: Colors.teal),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
