import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _corporateNavy = Color(0xFF1E3A5F);
  static const _corporateSlate = Color(0xFF4A5F7F);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: _corporateNavy.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.business_center,
                  size: 48,
                  color: _corporateNavy,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Alejandro Vance Rivas',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _corporateNavy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Senior Delivery & PMO Director',
                textAlign: TextAlign.center,
                style: textTheme.titleSmall?.copyWith(
                  color: _corporateSlate,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      value: '14',
                      label: 'Projects',
                      icon: Icons.folder_open_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KpiCard(
                      value: '98.4%',
                      label: 'SLA',
                      icon: Icons.verified_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      value: '37',
                      label: 'Active Risks',
                      icon: Icons.warning_amber_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KpiCard(
                      value: '12',
                      label: 'Teams Led',
                      icon: Icons.groups_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Change Avatar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _corporateNavy,
                    side: const BorderSide(color: _corporateNavy),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.security_outlined),
                  label: const Text('Security Settings'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _corporateNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: ProfileScreen._corporateSlate, size: 22),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ProfileScreen._corporateNavy,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ProfileScreen._corporateSlate,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
