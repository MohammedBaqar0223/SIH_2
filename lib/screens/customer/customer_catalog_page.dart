import 'package:flutter/material.dart';
import 'package:artesian/services/product_service.dart';
import 'package:artesian/theme/app_theme.dart';
import 'package:artesian/widgets/common.dart';

class CustomerCatalogPage extends StatefulWidget {
  const CustomerCatalogPage({super.key});

  @override
  State<CustomerCatalogPage> createState() => _CustomerCatalogPageState();
}

class _CustomerCatalogPageState extends State<CustomerCatalogPage> {
  late Future<List<dynamic>> catalogFuture;
  String _query = '';

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
            icon: const Icon(Icons.refresh_rounded),
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
            return ErrorState(
              title: 'Could not load marketplace',
              error: snapshot.error,
              onRetry: refreshCatalog,
            );
          }
          final all = snapshot.data ?? [];
          if (all.isEmpty) {
            return const EmptyState(
              icon: Icons.storefront_outlined,
              title: 'Nothing here yet',
              message: 'Published handcrafted products will appear here.',
            );
          }

          final q = _query.toLowerCase();
          final products = q.isEmpty
              ? all
              : all.where((p) {
                  return '${p['name']} ${p['material']} ${p['artisan']}'
                      .toLowerCase()
                      .contains(q);
                }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              refreshCatalog();
              await catalogFuture.catchError((_) => <dynamic>[]);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: const InputDecoration(
                        hintText: 'Search crafts, materials, artisans…',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                ),
                if (products.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No matches',
                      message: 'Try a different search term.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 240,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.68,
                          ),
                      itemCount: products.length,
                      itemBuilder: (context, index) =>
                          _CatalogCard(product: products[index]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final dynamic product;
  const _CatalogCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final id = (product['id'] as num).toInt();
    final photoUrl = productPhotoUrl(product);
    final price = (product['price_paise'] as num) / 100;
    final quantity = (product['quantity'] as num).toInt();

    return Card(
      clipBehavior: Clip.antiAlias,
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
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'catalog-$id',
                    child: ProductImage(url: photoUrl, iconSize: 48),
                  ),
                  if (quantity <= 3)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: StatusChip(
                        label: quantity == 0 ? 'Sold out' : 'Only $quantity left',
                        icon: Icons.local_fire_department_rounded,
                        color: Colors.white,
                        background: quantity == 0
                            ? Colors.black54
                            : AppColors.terracotta,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product['artisan']?.toString() ?? 'Artisan Studio',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatRupees(price),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.terracotta,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final id = (product['id'] as num).toInt();
    final photoUrl = productPhotoUrl(product);
    final price = (product['price_paise'] as num) / 100;
    final quantity = (product['quantity'] as num).toInt();
    final description = (product['description']?.toString() ?? '').trim();

    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.sand)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: quantity == 0
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added to cart')),
                          );
                        },
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('Add to cart'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: quantity == 0
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Buy now selected')),
                          );
                        },
                  icon: const Icon(Icons.flash_on_rounded),
                  label: const Text('Buy now'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: AppColors.cream,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  color: AppColors.ink,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'catalog-$id',
                child: ProductImage(url: photoUrl, iconSize: 80),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.sand,
                        child: Icon(
                          Icons.person_rounded,
                          size: 14,
                          color: AppColors.terracotta,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'by ${product['artisan']?.toString() ?? 'Artisan Studio'}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    formatRupees(price),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.terracotta,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.layers_outlined,
                          label: 'Material',
                          value: '${product['material']}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoTile(
                          icon: Icons.inventory_2_outlined,
                          label: 'Availability',
                          value: quantity == 0
                              ? 'Sold out'
                              : '$quantity in stock',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'About this piece',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description.isEmpty
                        ? 'A handcrafted artisan product.'
                        : description,
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sand),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.terracotta, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
