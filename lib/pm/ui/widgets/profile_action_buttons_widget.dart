import 'package:flutter/material.dart';
import 'package:mdeps_flutter/iam/ui/login_screen.dart';

class ProfileActionButtonsWidget extends StatefulWidget {
  const ProfileActionButtonsWidget({super.key});

  @override
  State<ProfileActionButtonsWidget> createState() =>
      _ProfileActionButtonsWidgetState();
}

class _ProfileActionButtonsWidgetState extends State<ProfileActionButtonsWidget> {
  static const _buttonHeight = 48.0;
  static const _borderRadius = BorderRadius.all(Radius.circular(12));

  String? _selectedLanguageCode;

  void _showCorporateSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: colorScheme.inverseSurface,
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: colorScheme.inversePrimary,
            onPressed: messenger.hideCurrentSnackBar,
          ),
        ),
      );
  }

  Future<void> _onLogout() async {
    _showCorporateSnackBar('Action triggered successfully');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _showLanguageBottomSheet() async {
    final colorScheme = Theme.of(context).colorScheme;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Select Language',
                    style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Icon(
                    Icons.language,
                    color: _selectedLanguageCode == 'en'
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  title: const Text('English (US)'),
                  trailing: _selectedLanguageCode == 'en'
                      ? Icon(Icons.check_circle, color: colorScheme.primary)
                      : null,
                  onTap: () => _onLanguageSelected(sheetContext, 'en'),
                ),
                ListTile(
                  leading: Icon(
                    Icons.language,
                    color: _selectedLanguageCode == 'es'
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  title: const Text('Español (ES)'),
                  trailing: _selectedLanguageCode == 'es'
                      ? Icon(Icons.check_circle, color: colorScheme.primary)
                      : null,
                  onTap: () => _onLanguageSelected(sheetContext, 'es'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onLanguageSelected(BuildContext sheetContext, String code) {
    Navigator.of(sheetContext).pop();
    setState(() => _selectedLanguageCode = code);

    final label = code == 'en' ? 'English (US)' : 'Español (ES)';
    _showCorporateSnackBar('Language updated to $label');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _buttonHeight,
          child: OutlinedButton.icon(
            onPressed: () {
              _showCorporateSnackBar('Feature in development for TB2');
            },
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Change Avatar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.outline),
              shape: const RoundedRectangleBorder(borderRadius: _borderRadius),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: _buttonHeight,
          child: FilledButton.icon(
            onPressed: () {
              _showCorporateSnackBar('Feature in development for TB2');
            },
            icon: const Icon(Icons.security_outlined),
            label: const Text('Security Settings'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: const RoundedRectangleBorder(borderRadius: _borderRadius),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: _buttonHeight,
          child: OutlinedButton.icon(
            onPressed: _showLanguageBottomSheet,
            icon: const Icon(Icons.language_outlined),
            label: const Text('Language Preferences (EN/ES)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.outline),
              shape: const RoundedRectangleBorder(borderRadius: _borderRadius),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: _buttonHeight,
          child: OutlinedButton.icon(
            onPressed: _onLogout,
            icon: Icon(Icons.logout, color: colorScheme.error),
            label: Text(
              'Logout',
              style: TextStyle(color: colorScheme.error),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.error.withValues(alpha: 0.6)),
              shape: const RoundedRectangleBorder(borderRadius: _borderRadius),
            ),
          ),
        ),
      ],
    );
  }
}
