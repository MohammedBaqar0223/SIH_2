import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artesian/screens/artisan/pricing_assistant_page.dart';
import 'package:artesian/services/product_service.dart';
import 'package:artesian/theme/app_theme.dart';
import 'package:artesian/widgets/common.dart';

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

  bool get isEditing => widget.product != null;

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
    FocusScope.of(context).unfocus();
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

  Widget _photoPicker() {
    final existingUrl = widget.product == null
        ? ''
        : productPhotoUrl(widget.product!);

    Widget content;
    if (selectedPhotoBytes != null) {
      content = Image.memory(
        selectedPhotoBytes!,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
      );
    } else if (existingUrl.isNotEmpty) {
      content = ProductImage(url: existingUrl, height: 200);
    } else {
      content = Container(
        height: 200,
        width: double.infinity,
        color: AppColors.sand.withValues(alpha: 0.5),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 44,
              color: AppColors.terracotta,
            ),
            SizedBox(height: 8),
            Text(
              'Tap to add a photo',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 2),
            Text(
              'Great photos help your craft sell',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final hasImage = selectedPhotoBytes != null || existingUrl.isNotEmpty;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: saving ? null : pickPhoto,
        child: Stack(
          children: [
            content,
            if (hasImage)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Change photo',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit product' : 'New product'),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton.icon(
              onPressed: saving ? null : saveProduct,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                saving
                    ? 'Saving…'
                    : (isEditing ? 'Save changes' : 'Add product'),
              ),
            ),
          ),
        ),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _photoPicker(),
              const SizedBox(height: 16),
              SectionCard(
                icon: Icons.label_outline_rounded,
                title: 'Basic details',
                children: [
                  TextFormField(
                    controller: nameController,
                    enabled: !saving,
                    maxLength: 120,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Product name',
                      hintText: 'e.g. Hand-painted clay vase',
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a product name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: materialController,
                    enabled: !saving,
                    maxLength: 100,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Material',
                      hintText: 'e.g. Terracotta, Teak wood',
                      prefixIcon: Icon(Icons.layers_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter the material';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: artisanController,
                    enabled: !saving,
                    maxLength: 120,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Artisan / studio name',
                      hintText: 'Artisan Studio',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descriptionController,
                    enabled: !saving,
                    maxLength: 500,
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Tell buyers the story behind this piece…',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                icon: Icons.sell_outlined,
                title: 'Pricing & stock',
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: priceController,
                          enabled: !saving,
                          textInputAction: TextInputAction.next,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            prefixText: '$rupee ',
                            hintText: '450.00',
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) {
                              return 'Enter a valid price';
                            }

                            final price = double.tryParse(text);
                            if (price == null ||
                                !price.isFinite ||
                                price > 10000000) {
                              return 'Max ${rupee}1,00,00,000';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: quantityController,
                          enabled: !saving,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            hintText: '10',
                            suffixText: 'pcs',
                          ),
                          validator: (value) {
                            final quantity = int.tryParse(value?.trim() ?? '');
                            if (quantity == null ||
                                quantity < 0 ||
                                quantity > 1000000) {
                              return '0 – 1,000,000';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PricingAssistantPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Not sure? Use the pricing assistant'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}