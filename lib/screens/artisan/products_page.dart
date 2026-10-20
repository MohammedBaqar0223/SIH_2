import 'package:flutter/material.dart';
import 'package:artesian/services/product_service.dart';
import 'package:artesian/screens/artisan/add_product_page.dart';
import 'package:artesian/screens/customer/customer_catalog_page.dart';
import 'package:artesian/theme/app_theme.dart';
import 'package:artesian/widgets/common.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late Future<List<dynamic>> productsFuture;
  final Set<int> _publishing = {};

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

  Future<void> _openEditor([Map<String, dynamic>? product]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddProductPage(product: product)),
    );
    if (!mounted) return;
    if (saved == true) {
      refreshProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(product == null ? 'Product added' : 'Changes saved'),
        ),
      );
    }
  }

  Future<void> _publish(int id) async {
    setState(() => _publishing.add(id));
    try {
      await publishProduct(id);
      if (!mounted) return;
      refreshProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Published to marketplace 🎉')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not publish: $error')));
    } finally {
      if (mounted) setState(() => _publishing.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add product',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () => _openEditor(),
      ),
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          future: productsFuture,
          builder: (context, snapshot) {
            final loading = snapshot.connectionState != ConnectionState.done;
            final products = snapshot.data ?? [];

            return RefreshIndicator(
              onRefresh: () async {
                refreshProducts();
                await productsFuture.catchError((_) => <dynamic>[]);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(products, loading)),
                  if (loading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ErrorState(
                        title: 'Could not load products',
                        error: 'Backend: $backendUrl\n${snapshot.error}',
                        onRetry: refreshProducts,
                      ),
                    )
                  else if (products.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'No products yet',
                        message:
                            'Add your first handcrafted piece and share it '
                            'with the marketplace.',
                        action: FilledButton.icon(
                          onPressed: () => _openEditor(),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add your first product'),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      sliver: SliverList.separated(
                        itemCount: products.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _buildProductCard(products[index]),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(List<dynamic> products, bool loading) {
    final published = products
        .where((p) => p['published'] == 1 || p['published'] == true)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back 👋',
                      style: TextStyle(color: AppColors.muted, fontSize: 14),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'My Studio',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: refreshProducts,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh products',
              ),
              const SizedBox(width: 4),
              IconButton.filled(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CustomerCatalogPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.storefront_rounded),
                tooltip: 'Open marketplace',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.terracotta.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _stat('Products', loading ? '–' : '${products.length}'),
                Container(width: 1, height: 40, color: Colors.white24),
                _stat('Published', loading ? '–' : '$published'),
                Container(width: 1, height: 40, color: Colors.white24),
                _stat(
                  'Drafts',
                  loading ? '–' : '${products.length - published}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _buildProductCard(dynamic product) {
    final id = (product['id'] as num).toInt();
    final price = (product['price_paise'] as num) / 100;
    final quantity = (product['quantity'] as num).toInt();
    final photoUrl = productPhotoUrl(product);
    final published = product['published'] == 1 || product['published'] == true;
    final publishing = _publishing.contains(id);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openEditor(Map<String, dynamic>.from(product)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Hero(
                tag: 'product-$id',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ProductImage(url: photoUrl, width: 88, height: 88),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${product['material']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          formatRupees(price),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.terracotta,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          quantity == 0 ? 'Out of stock' : '$quantity in stock',
                          style: TextStyle(
                            fontSize: 12,
                            color: quantity == 0
                                ? Colors.red.shade400
                                : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (published)
                      const StatusChip(
                        label: 'Live on marketplace',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.sage,
                        background: AppColors.sageLight,
                      )
                    else
                      SizedBox(
                        height: 34,
                        child: FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 34),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: publishing ? null : () => _publish(id),
                          icon: publishing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.rocket_launch_rounded, size: 16),
                          label: Text(publishing ? 'Publishing…' : 'Publish'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
