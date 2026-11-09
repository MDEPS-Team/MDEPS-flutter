import 'package:flutter/material.dart';

class ProfileHeaderWidget extends StatelessWidget {
  const ProfileHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        CircleAvatar(
          radius: 56,
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            Icons.person,
            size: 56,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 16),
        Chip(
          label: const Text('Verified corporate ID'),
          labelStyle: textTheme.labelMedium?.copyWith(
            color: colorScheme.onTertiaryContainer,
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: colorScheme.tertiaryContainer,
          side: BorderSide(color: colorScheme.tertiary.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        const SizedBox(height: 16),
        Text(
          'Alejandro Vance Rivas',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Senior Delivery & PMO Director',
          textAlign: TextAlign.center,
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
