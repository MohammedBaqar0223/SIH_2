import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// This address connects an Android emulator to your laptop.
const backendUrl = 'http://10.0.2.2:8000';
//const backendUrl = 'http://127.0.0.1:8000';

void main() {
  runApp(const ArtisanApp());
}

// Fetch the product list from Python.
Future<List<dynamic>> fetchProducts() async {
  final url = Uri.parse('$backendUrl/products');

  final response = await http.get(url).timeout(const Duration(seconds: 15));

  if (response.statusCode != 200) {
    throw Exception('Backend returned error ${response.statusCode}');
  }

  // Convert JSON text into a Dart list.
  return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
}

Future<Map<String, dynamic>> createProduct({
  required String name,
  required String material,
  required int pricePaise,
  required int quantity,
}) async {
  final response = await http
      .post(
        Uri.parse('$backendUrl/products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'material': material,
          'price_paise': pricePaise,
          'quantity': quantity,
        }),
      )
      .timeout(const Duration(seconds: 15));

  if (response.statusCode != 201) {
    throw Exception(
      'Could not add product: ${response.statusCode}\n'
      '${response.body}',
    );
  }

  return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> updateProduct({
  required int id,
  required String name,
  required String material,
  required int pricePaise,
  required int quantity,
}) async {
  final response = await http
      .put(
        Uri.parse('$backendUrl/products/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'material': material,
          'price_paise': pricePaise,
          'quantity': quantity,
        }),
      )
      .timeout(const Duration(seconds: 15));

  if (response.statusCode != 200) {
    throw Exception(
      'Could not update product: ${response.statusCode}\n'
      '${response.body}',
    );
  }

  return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
}

String productPhotoUrl(Map<String, dynamic> product) {
  final photoPath = product['photo_path'];
  if (photoPath is! String || photoPath.trim().isEmpty) {
    return '';
  }
  return '$backendUrl$photoPath';
}

Future<void> uploadProductPhoto({
  required int productId,
  required XFile photo,
}) async {
  final bytes = await photo.readAsBytes();
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('$backendUrl/products/$productId/photo'),
  );

  request.files.add(
    http.MultipartFile.fromBytes('file', bytes, filename: photo.name),
  );

  final streamed = await request.send().timeout(const Duration(seconds: 15));
  final response = await http.Response.fromStream(streamed);

  if (response.statusCode != 200) {
    throw Exception(
      'Could not upload photo: ${response.statusCode}\n'
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
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const ProductsPage(),
    );
  }
}

class PricingAssistantPage extends StatefulWidget {
  const PricingAssistantPage({super.key});

  @override
  State<PricingAssistantPage> createState() => _PricingAssistantPageState();
}

class _PricingAssistantPageState extends State<PricingAssistantPage> {
  final materialCostController = TextEditingController(text: '100');
  final labourCostController = TextEditingController(text: '80');
  final packagingCostController = TextEditingController(text: '20');
  final overheadCostController = TextEditingController(text: '30');

  double suggestedPrice = 0;
  String explanation = '';

  void calculatePricing() {
    final material = double.tryParse(materialCostController.text.trim()) ?? 0;
    final labour = double.tryParse(labourCostController.text.trim()) ?? 0;
    final packaging = double.tryParse(packagingCostController.text.trim()) ?? 0;
    final overhead = double.tryParse(overheadCostController.text.trim()) ?? 0;

    final directCost = material + labour + packaging + overhead;
    final labourAndMargin = directCost * 0.35;
    suggestedPrice = directCost + labourAndMargin;

    explanation =
        'Base cost is ₹${directCost.toStringAsFixed(2)}. '
        'The assistant adds a 35% artisan margin and explains a fair suggested '
        'retail price of ₹${suggestedPrice.toStringAsFixed(2)}.';

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pricing Assistant')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Pricing Assistant',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Enter project costs and get a suggested price.'),
            const SizedBox(height: 24),
            _PricingField(
              label: 'Material cost',
              controller: materialCostController,
              hint: '₹',
            ),
            const SizedBox(height: 12),
            _PricingField(
              label: 'Labour cost',
              controller: labourCostController,
              hint: '₹',
            ),
            const SizedBox(height: 12),
            _PricingField(
              label: 'Packaging cost',
              controller: packagingCostController,
              hint: '₹',
            ),
            const SizedBox(height: 12),
            _PricingField(
              label: 'Overhead cost',
              controller: overheadCostController,
              hint: '₹',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: calculatePricing,
              icon: const Icon(Icons.calculate),
              label: const Text('Create price suggestion'),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Suggested price',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '₹${suggestedPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Breakdown',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      explanation.isEmpty
                          ? 'Enter costs to see a breakdown.'
                          : explanation,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PricingField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _PricingField({
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
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
          // State 1: Still waiting for the backend.
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
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
            return const Center(child: Text('No products yet'));
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final price = (product['price_paise'] as num) / 100;
              final photoUrl = productPhotoUrl(product);

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

class AddProductPage extends StatefulWidget {
  final Map<String, dynamic>? product;
  const AddProductPage({super.key, this.product});
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
  XFile? selectedPhoto;
  Uint8List? selectedPhotoBytes;
  String? photoPath;

  bool saving = false;

  Future<void> pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();

    setState(() {
      selectedPhoto = image;
      selectedPhotoBytes = bytes;
      photoPath = image.path;
    });
  }

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    if (product != null) {
      nameController.text = product['name'].toString();
      materialController.text = product['material'].toString();

      final pricePaise = (product['price_paise'] as num).toInt();

      priceController.text =
          '${pricePaise ~/ 100}.'
          '${(pricePaise % 100).toString().padLeft(2, '0')}';

      quantityController.text = product['quantity'].toString();
    }
  }

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
      final name = nameController.text.trim();
      final material = materialController.text.trim();
      final pricePaise = rupees * 100 + paise;
      final quantity = int.parse(quantityController.text.trim());
      Map<String, dynamic> savedProduct;
      if (widget.product == null) {
        savedProduct = await createProduct(
          name: name,
          material: material,
          pricePaise: pricePaise,
          quantity: quantity,
        );
      } else {
        savedProduct = await updateProduct(
          id: (widget.product!['id'] as num).toInt(),
          name: name,
          material: material,
          pricePaise: pricePaise,
          quantity: quantity,
        );
      }

      final productId = (savedProduct['id'] as num).toInt();
      if (selectedPhoto != null) {
        await uploadProductPhoto(productId: productId, photo: selectedPhoto!);
      }

      if (!mounted) return;

      // Close the form and tell the previous screen it was saved.
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not confirm the save: $error')),
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
          title: Text(widget.product == null ? 'Add product' : 'Edit product'),
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

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Photo-first product detail',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedPhoto == null
                                  ? 'No photo selected'
                                  : selectedPhoto!.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: saving ? null : pickPhoto,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Choose photo'),
                          ),
                        ],
                      ),
                      if (selectedPhotoBytes != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              selectedPhotoBytes!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PricingAssistantPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.price_change),
                        label: const Text('Open pricing assistant'),
                      ),
                    ],
                  ),
                ),
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
                  if (price == null || !price.isFinite || price > 10000000) {
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

                  if (quantity == null || quantity < 0 || quantity > 1000000) {
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
                  child: Text(saving ? 'Saving...' : 'Save product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
