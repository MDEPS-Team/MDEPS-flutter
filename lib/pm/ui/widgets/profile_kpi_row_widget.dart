import 'package:flutter/material.dart';

class ProfileKpiRowWidget extends StatelessWidget {
  const ProfileKpiRowWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _ProfileKpiCard(
            value: '14',
            label: 'Projects',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _ProfileKpiCard(
            value: '98.4%',
            label: 'SLA',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _ProfileKpiCard(
            value: '32',
            label: 'Team Members',
          ),
        ),
      ],
    );
  }
}

class _ProfileKpiCard extends StatelessWidget {
  const _ProfileKpiCard({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
