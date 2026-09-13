import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artesian/screens/artisan/pricing_assistant_page.dart';
import 'package:artesian/services/product_service.dart';

class AddProductPage extends StatefulWidget {
  final Map<String, dynamic>? product;
  const AddProductPage({super.key, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final materialController = TextEditingController();
  final descriptionController = TextEditingController(text: '');
  final artisanController = TextEditingController(text: 'Artisan Studio');
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
      descriptionController.text = product['description']?.toString() ?? '';
      artisanController.text =
          product['artisan']?.toString() ?? 'Artisan Studio';

      final pricePaise = (product['price_paise'] as num).toInt();
      priceController.text =
          '${pricePaise ~/ 100}.'
          '${(pricePaise % 100).toString().padLeft(2, '0')}';

      quantityController.text = product['quantity'].toString();
    }
  }

  Future<void> saveProduct() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      saving = true;
    });

    try {
      final priceParts = priceController.text.trim().split('.');
      final rupees = int.parse(priceParts[0]);
      final paise = priceParts.length == 2
          ? int.parse(priceParts[1].padRight(2, '0'))
          : 0;

      final name = nameController.text.trim();
      final material = materialController.text.trim();
      final description = descriptionController.text.trim();
      final artisan = artisanController.text.trim().isEmpty
          ? 'Artisan Studio'
          : artisanController.text.trim();
      final pricePaise = rupees * 100 + paise;
      final quantity = int.parse(quantityController.text.trim());

      Map<String, dynamic> savedProduct;
      if (widget.product == null) {
        savedProduct = await createProduct(
          name: name,
          material: material,
          pricePaise: pricePaise,
          quantity: quantity,
          description: description,
          artisan: artisan,
        );
      } else {
        savedProduct = await updateProduct(
          id: (widget.product!['id'] as num).toInt(),
          name: name,
          material: material,
          pricePaise: pricePaise,
          quantity: quantity,
          description: description,
          artisan: artisan,
        );
      }

      final productId = (savedProduct['id'] as num).toInt();
      if (selectedPhoto != null) {
        await uploadProductPhoto(productId: productId, photo: selectedPhoto!);
      }

      if (!mounted) return;
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
    descriptionController.dispose();
    artisanController.dispose();
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
              TextFormField(
                controller: artisanController,
                enabled: !saving,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Artisan detail',
                  hintText: 'Artisan Studio',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                enabled: !saving,
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
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
