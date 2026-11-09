import 'package:flutter/material.dart';
import 'package:mdeps_flutter/pm/ui/widgets/profile_action_buttons_widget.dart';
import 'package:mdeps_flutter/pm/ui/widgets/profile_header_widget.dart';
import 'package:mdeps_flutter/pm/ui/widgets/profile_kpi_row_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _screenPadding = 24.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: colorScheme.surface,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(_screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileHeaderWidget(),
            SizedBox(height: 28),
            ProfileKpiRowWidget(),
            SizedBox(height: 32),
            ProfileActionButtonsWidget(),
          ],
        ),
      ),
    );
  }
}
