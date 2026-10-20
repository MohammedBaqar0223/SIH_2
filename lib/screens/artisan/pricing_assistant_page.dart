import 'package:flutter/material.dart';
import 'package:artesian/theme/app_theme.dart';
import 'package:artesian/widgets/common.dart';

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

  static const marginRate = 0.35;

  double directCost = 0;
  double suggestedPrice = 0;
  String explanation = '';

  @override
  void initState() {
    super.initState();
    for (final c in _controllers) {
      c.addListener(calculatePricing);
    }
    calculatePricing();
  }

  List<TextEditingController> get _controllers => [
    materialCostController,
    labourCostController,
    packagingCostController,
    overheadCostController,
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void calculatePricing() {
    final material = double.tryParse(materialCostController.text.trim()) ?? 0;
    final labour = double.tryParse(labourCostController.text.trim()) ?? 0;
    final packaging = double.tryParse(packagingCostController.text.trim()) ?? 0;
    final overhead = double.tryParse(overheadCostController.text.trim()) ?? 0;

    directCost = material + labour + packaging + overhead;
    final labourAndMargin = directCost * marginRate;
    suggestedPrice = directCost + labourAndMargin;

    explanation =
        'Base cost is ${formatRupees(directCost)}. '
        'The assistant adds a 35% artisan margin for a fair suggested '
        'retail price of ${formatRupees(suggestedPrice)}.';

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pricing assistant')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Colors.white70),
                      SizedBox(width: 6),
                      Text(
                        'Suggested price',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: suggestedPrice),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => Text(
                      formatRupees(value),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _pill('Cost', formatRupees(directCost)),
                      const SizedBox(width: 8),
                      _pill(
                        'Margin 35%',
                        formatRupees(suggestedPrice - directCost),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              icon: Icons.receipt_long_outlined,
              title: 'Your costs',
              children: [
                _PricingField(
                  label: 'Material cost',
                  icon: Icons.layers_outlined,
                  controller: materialCostController,
                ),
                const SizedBox(height: 12),
                _PricingField(
                  label: 'Labour cost',
                  icon: Icons.handyman_outlined,
                  controller: labourCostController,
                ),
                const SizedBox(height: 12),
                _PricingField(
                  label: 'Packaging cost',
                  icon: Icons.inventory_2_outlined,
                  controller: packagingCostController,
                ),
                const SizedBox(height: 12),
                _PricingField(
                  label: 'Overhead cost',
                  icon: Icons.bolt_outlined,
                  controller: overheadCostController,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.sageLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppColors.sage),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      explanation,
                      style: const TextStyle(height: 1.4),
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

  Widget _pill(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _PricingField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;

  const _PricingField({
    required this.label,
    required this.icon,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        prefixText: '$rupee ',
      ),
    );
  }
}
