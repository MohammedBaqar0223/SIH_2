import 'package:flutter/material.dart';
import 'package:artesian/services/product_service.dart';

class CustomerCatalogPage extends StatefulWidget {
  const CustomerCatalogPage({super.key});

  @override
  State<CustomerCatalogPage> createState() => _CustomerCatalogPageState();
}

class _CustomerCatalogPageState extends State<CustomerCatalogPage> {
  late Future<List<dynamic>> catalogFuture;

  @override
  void initState() {
    super.initState();
    catalogFuture = fetchPublishedProducts();
  }

  void refreshCatalog() {
    setState(() {
      catalogFuture = fetchPublishedProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            onPressed: refreshCatalog,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh catalog',
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: catalogFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load marketplace: ${snapshot.error}'),
              ),
            );
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('No published products yet'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final photoUrl = productPhotoUrl(product);
              final price = (product['price_paise'] as num) / 100;
              return SizedBox(
                child: Card(
                  elevation: 4,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductDetailPage(product: product),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: photoUrl.isEmpty
                              ? Container(
                                  height: 150,
                                  color: Colors.teal.shade50,
                                  child: const Center(
                                    child: Icon(
                                      Icons.shopping_basket,
                                      color: Colors.teal,
                                      size: 50,
                                    ),
                                  ),
                                )
                              : Image.network(
                                  photoUrl,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 150,
                                      color: Colors.teal.shade50,
                                      child: const Center(
                                        child: Icon(
                                          Icons.shopping_basket,
                                          color: Colors.teal,
                                          size: 50,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                product['artisan']?.toString() ??
                                    'Artisan Studio',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              Text(
                                '₹${price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.teal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Stock: ${product['quantity']}',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
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

class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final photoUrl = productPhotoUrl(product);
    final price = (product['price_paise'] as num) / 100;

    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: photoUrl.isEmpty
                  ? Container(
                      height: 260,
                      color: Colors.teal.shade50,
                      child: const Center(
                        child: Icon(
                          Icons.shopping_basket,
                          color: Colors.teal,
                          size: 80,
                        ),
                      ),
                    )
                  : Image.network(
                      photoUrl,
                      height: 260,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 260,
                          color: Colors.teal.shade50,
                          child: const Center(
                            child: Icon(
                              Icons.shopping_basket,
                              color: Colors.teal,
                              size: 80,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
            Text(
              product['name'],
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              product['artisan']?.toString() ?? 'Artisan Studio',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Text(
              'Material: ${product['material']}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Price: ₹${price.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Available: ${product['quantity']}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text(
              product['description']?.toString() ??
                  'A handcrafted artisan product.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to cart')),
                      );
                    },
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Add to Cart'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Buy now selected')),
                      );
                    },
                    icon: const Icon(Icons.payment),
                    label: const Text('Buy Now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
