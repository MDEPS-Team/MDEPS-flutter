import 'package:flutter/material.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_brand.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_controls.dart';

/// Preset avatar palettes (no photo-picker plugin in this static build).
const avatarPresets = [
  [Color(0xFF0B57D0), Color(0xFF063B8E)],
  [Color(0xFF0B7A4B), Color(0xFF075234)],
  [Color(0xFF7B3FE4), Color(0xFF4B1FA0)],
  [Color(0xFFEF6C00), Color(0xFFB34A00)],
  [Color(0xFF1A1F2B), Color(0xFF4A5364)],
];

const avatarPresetPrefix = 'preset:';

int? avatarPresetIndex(String? reference) {
  if (reference == null || !reference.startsWith(avatarPresetPrefix)) {
    return null;
  }
  return int.tryParse(reference.substring(avatarPresetPrefix.length));
}

/// Profile avatar: preset gradient with initials, or the person icon.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.initials, required this.reference, this.size = 112});

  final String initials;
  final String? reference;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final index = avatarPresetIndex(reference);
    return Semantics(
      image: true,
      label: context.tr('iam_a11y_profile_avatar'),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: index == null ? p.blueSoft : null,
          gradient: index == null
              ? null
              : LinearGradient(
                  colors: avatarPresets[index % avatarPresets.length],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: index == null
            ? Icon(Icons.person, size: size * 0.43, color: Vx.blue)
            : Text(
                initials,
                style: TextStyle(color: Colors.white, fontSize: size * 0.34, fontWeight: FontWeight.w800),
              ),
      ),
    );
  }
}

/// "Update profile photo" sheet. Pops with the chosen avatar reference.
class AvatarPickerSheet extends StatefulWidget {
  const AvatarPickerSheet({super.key, required this.initials, required this.current});

  final String initials;
  final String? current;

  @override
  State<AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<AvatarPickerSheet> {
  late int _selected = avatarPresetIndex(widget.current) ?? 0;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('pm_avatar_sheet_title'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: p.ink),
            ),
            const SizedBox(height: 4),
            Text(context.tr('pm_avatar_sheet_subtitle'), style: TextStyle(color: p.muted)),
            const SizedBox(height: 20),
            Center(
              child: ProfileAvatar(initials: widget.initials, reference: '$avatarPresetPrefix$_selected', size: 96),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('pm_avatar_initials').toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: p.muted),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < avatarPresets.length; i++)
                  Semantics(
                    button: true,
                    selected: i == _selected,
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = i),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: avatarPresets[i]),
                          border: Border.all(color: i == _selected ? p.ink : Colors.transparent, width: 3),
                        ),
                        child: i == _selected ? const Icon(Icons.check, color: Colors.white) : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            VxButton(
              text: context.tr('pm_avatar_apply'),
              style: VxButtonStyle.blue,
              leadingIcon: Icons.check,
              onPressed: () => Navigator.pop(context, '$avatarPresetPrefix$_selected'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Security settings sheet: corporate email, employee id and 2FA.
class SecuritySheet extends StatefulWidget {
  const SecuritySheet({super.key, required this.corporateEmail, required this.onEmailChange});

  final String corporateEmail;
  final ValueChanged<String> onEmailChange;

  @override
  State<SecuritySheet> createState() => _SecuritySheetState();
}

class _SecuritySheetState extends State<SecuritySheet> {
  late final _email = TextEditingController(text: widget.corporateEmail);
  bool _showEmployeeId = false;
  bool _showTwoFactor = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('iam_security_sheet_title'),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: p.ink),
                    ),
                  ),
                  IconButton(
                    tooltip: context.tr('iam_a11y_security_close'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.email),
                title: Text(context.tr('iam_security_change_email'), style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.keyboard_arrow_right),
                onTap: () => setState(() {
                  _showEmployeeId = false;
                  _showTwoFactor = false;
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: widget.onEmailChange,
                  decoration: InputDecoration(
                    labelText: context.tr('iam_login_corporate_email_label'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.badge),
                title: Text(context.tr('iam_security_view_id'), style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.keyboard_arrow_right),
                onTap: () => setState(() {
                  _showEmployeeId = !_showEmployeeId;
                  _showTwoFactor = false;
                }),
              ),
              if (_showEmployeeId)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('iam_security_employee_id_label'), style: TextStyle(fontSize: 12, color: p.muted)),
                      Text(
                        context.tr('iam_security_employee_id_value'),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.ink),
                      ),
                    ],
                  ),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.lock),
                title: Text(context.tr('iam_security_change_2fa'), style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.keyboard_arrow_right),
                onTap: () => setState(() {
                  _showTwoFactor = !_showTwoFactor;
                  _showEmployeeId = false;
                }),
              ),
              if (_showTwoFactor)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(context.tr('iam_biometric_subtitle'), style: TextStyle(color: p.muted)),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logout confirmation (Figma "Confirmar cerrar sesión"). Pops with true to log out.
class LogoutConfirmDialog extends StatelessWidget {
  const LogoutConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return AlertDialog(
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: p.redSoft, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.logout, color: Vx.red),
      ),
      title: Text(context.tr('pm_logout_confirm_title'), textAlign: TextAlign.center),
      content: Text(
        context.tr('pm_logout_confirm_body'),
        textAlign: TextAlign.center,
        style: TextStyle(color: p.muted),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('pm_logout_confirm_cancel'))),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: Vx.red),
          child: Text(context.tr('pm_logout_confirm_action')),
        ),
      ],
    );
  }
}

/// Short success dialog (Figma "Confirmación de cambios exitosa" /
/// "Cierre de sesión exitoso"); closes itself.
Future<void> showSuccessToast(BuildContext context, {required String title, String? body}) async {
  final navigator = Navigator.of(context);
  final future = showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final p = dialogContext.vx;
      return Dialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AnimatedSuccessMark(size: 64),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.ink),
              ),
              if (body != null) ...[
                const SizedBox(height: 6),
                Text(body, textAlign: TextAlign.center, style: TextStyle(color: p.muted)),
              ],
            ],
          ),
        ),
      );
    },
  );
  await Future.any([future, Future<void>.delayed(const Duration(milliseconds: 1400))]);
  if (navigator.mounted && navigator.canPop()) {
    navigator.pop();
  }
}
