import 'package:flutter/material.dart';

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
