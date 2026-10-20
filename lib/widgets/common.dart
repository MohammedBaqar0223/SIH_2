import 'package:flutter/material.dart';
import 'package:artesian/theme/app_theme.dart';
import 'package:artesian/services/product_service.dart' show apiHeaders;

/// Network product photo with a soft placeholder, loading shimmer and fallback.
class ProductImage extends StatelessWidget {
  final String url;
  final double? height;
  final double? width;
  final double iconSize;

  const ProductImage({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.iconSize = 40,
  });

  Widget _placeholder() => Container(
    height: height,
    width: width ?? double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.sand, Color(0xFFF7EBDD)],
      ),
    ),
    child: Icon(
      Icons.palette_outlined,
      color: AppColors.clay,
      size: iconSize,
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();
    return Image.network(
      url,
      headers: apiHeaders,
      height: height,
      width: width ?? double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Stack(
          alignment: Alignment.center,
          children: [
            _placeholder(),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        );
      },
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  const StatusChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.sand,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.terracotta),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;
  final String title;

  const ErrorState({
    super.key,
    required this.error,
    required this.onRetry,
    this.title = 'Something went wrong',
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: title,
      message: 'Check your connection and try again.',
      action: Column(
        children: [
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(
              context,
            ).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text(
                'Technical details',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              children: [
                SelectableText(
                  '$error',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// White rounded card with an icon header, used to group form fields.
class SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.terracotta),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
