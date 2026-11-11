import 'package:flutter/material.dart';
import 'package:mdeps_flutter/core/app_scope.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/core/ui/shell_navigator.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_widgets.dart';
import 'package:mdeps_flutter/pm/application/profile_controller.dart';
import 'package:mdeps_flutter/pm/domain/profile_models.dart';
import 'package:mdeps_flutter/pm/ui/widgets/profile_sheets.dart';

/// Profile management: hero, KPIs, account & security, PMO preferences,
/// language, access tier, save and logout.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.onLogout});

  /// Ends the session; provided by the app shell.
  final Future<void> Function()? onLogout;

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => const LogoutConfirmDialog());
    if (ok == true && context.mounted) {
      await showSuccessToast(
        context,
        title: context.tr('pm_logout_done_title'),
        body: context.tr('pm_logout_done_body'),
      );
      await onLogout?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final profile = services.profile;
    final nav = ShellScope.of(context);
    final p = context.vx;

    return ListenableBuilder(
      listenable: profile,
      builder: (context, _) {
        final s = profile.state;
        final user = s.user;
        final op = profile.operational;
        return Scaffold(
          backgroundColor: p.bg,
          appBar: VxTopBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Caption(context.tr('iam_login_title'), color: Vx.blue),
                Text(
                  context.tr('iam_profile_title'),
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: p.ink),
                ),
              ],
            ),
            actions: [
              if (s.sessionActive)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(child: Pill(context.tr('gro_governance_active'), bg: p.greenSoft, fg: Vx.green)),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeroCard(
                name: user?.name ?? '',
                role: user?.role ?? '',
                initials: user?.initials ?? '?',
                avatar: user?.avatarPath,
                workspace: op.workspace,
                onChangeAvatar: () async {
                  final ref = await showModalBottomSheet<String>(
                    context: context,
                    builder: (_) => AvatarPickerSheet(initials: user?.initials ?? '?', current: user?.avatarPath),
                  );
                  if (ref != null && context.mounted) {
                    await profile.saveAvatar(ref);
                    if (context.mounted) {
                      showVxSnack(context, context.tr('iam_profile_avatar_updated'));
                    }
                  }
                },
              ),
              const SizedBox(height: 14),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _KpiCard(
                        label: context.tr('iam_profile_kpi_projects'),
                        value: '${s.metrics.projectCount}',
                        subtitle: context.tr('iam_profile_kpi_on_track', [s.metrics.projectsOnTrack]),
                        icon: Icons.summarize,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _KpiCard(
                        label: context.tr('iam_profile_kpi_sla'),
                        value: context.tr('iam_profile_kpi_sla_value', [s.metrics.slaAdherencePercent.toStringAsFixed(1)]),
                        subtitle: context.tr('iam_profile_kpi_sla_delta', [
                          '${s.metrics.slaDeltaPercent >= 0 ? '+' : ''}${s.metrics.slaDeltaPercent.toStringAsFixed(1)}',
                        ]),
                        icon: Icons.shield,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _KpiCard(
                        label: context.tr('iam_profile_kpi_team'),
                        value: '${s.metrics.teamMemberCount}',
                        subtitle: context.tr('iam_profile_kpi_pods', [s.metrics.podCount]),
                        icon: Icons.groups,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _AccountSecurity(
                email: profile.draftEmail,
                passwordDaysAgo: s.passwordDaysAgo,
                onEdit: () => _openSecurity(context, profile),
              ),
              const SizedBox(height: 14),
              _PmoPreferences(controller: profile),
              const SizedBox(height: 14),
              const _LanguagePreferences(),
              const SizedBox(height: 14),
              _AccessGovernance(
                tenantId: profile.vantageTenantId(),
                auditRecords: s.auditRecordCount,
                onOpenAudit: () => nav.goTab(AppTab.governance),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: profile.isSaving
                    ? null
                    : () async {
                        await profile.saveProfile();
                        if (context.mounted) {
                          await showSuccessToast(context, title: context.tr('pm_profile_saved_title'));
                          if (context.mounted) {
                            showVxSnack(context, context.tr('iam_profile_saved'));
                          }
                        }
                      },
                style: FilledButton.styleFrom(backgroundColor: Vx.blue, minimumSize: const Size.fromHeight(48)),
                icon: profile.isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check),
                label: Text(context.tr('iam_profile_save'), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => _logout(context),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                icon: const Icon(Icons.logout, color: Vx.red),
                label: Text(
                  context.tr('iam_profile_logout'),
                  style: const TextStyle(color: Vx.red, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _openSecurity(BuildContext context, ProfileController profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SecuritySheet(corporateEmail: profile.draftEmail, onEmailChange: profile.setDraftEmail),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.name,
    required this.role,
    required this.initials,
    required this.avatar,
    required this.workspace,
    required this.onChangeAvatar,
  });

  final String name;
  final String role;
  final String initials;
  final String? avatar;
  final ProfileWorkspacePrefs workspace;
  final VoidCallback onChangeAvatar;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return VxCard(
      child: Column(
        children: [
          Container(
            height: 96,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B57D0), Color(0xFF063B8E)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                Stack(
                  children: [
                    ProfileAvatar(initials: initials, reference: avatar),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Material(
                        color: Vx.blue,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: onChangeAvatar,
                          child: Tooltip(
                            message: context.tr('iam_profile_change_avatar'),
                            child: const SizedBox(
                              width: 36,
                              height: 36,
                              child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Pill(context.tr('iam_profile_verified_badge').toUpperCase(), bg: p.greenSoft, fg: Vx.green),
                const SizedBox(height: 10),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: p.ink),
                ),
                Text(
                  role,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Vx.blue, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _MetaChip(icon: Icons.business, text: workspace.organization),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _MetaChip(icon: Icons.location_on, text: workspace.location)),
                    const SizedBox(width: 12),
                    Expanded(child: _MetaChip(icon: Icons.layers, text: workspace.floorLabel)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Row(
      children: [
        Icon(icon, size: 16, color: p.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: p.muted),
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value, required this.subtitle, required this.icon});

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return VxCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Caption(label)),
              Icon(icon, size: 18, color: p.muted),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: p.ink)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(subtitle, style: const TextStyle(fontSize: 11, color: Vx.green)),
          ),
        ],
      ),
    );
  }
}

class _AccountSecurity extends StatelessWidget {
  const _AccountSecurity({required this.email, required this.passwordDaysAgo, required this.onEdit});

  final String email;
  final int passwordDaysAgo;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return VxCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('iam_profile_account_security'),
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: p.ink),
                ),
              ),
              TextButton(
                onPressed: onEdit,
                child: Text(
                  context.tr('iam_profile_edit'),
                  style: const TextStyle(color: Vx.blue, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          _SecurityRow(
            icon: Icons.email,
            title: context.tr('iam_profile_corp_email'),
            subtitle: email,
            trailing: Icon(Icons.lock, size: 16, color: p.muted),
          ),
          Divider(color: p.line),
          _SecurityRow(
            icon: Icons.verified_user,
            title: context.tr('iam_profile_sso_title'),
            subtitle: context.tr('iam_profile_sso_sub'),
            trailing: Pill(context.tr('iam_profile_status_active'), bg: p.blueSoft, fg: Vx.blue),
          ),
          Divider(color: p.line),
          _SecurityRow(
            icon: Icons.shield,
            title: context.tr('iam_profile_2fa_title'),
            subtitle: context.tr('iam_profile_2fa_sub'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 16, color: Vx.green),
                const SizedBox(width: 4),
                Text(
                  context.tr('iam_profile_status_enforced'),
                  style: const TextStyle(color: Vx.green, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Divider(color: p.line),
          InkWell(
            onTap: onEdit,
            child: _SecurityRow(
              icon: Icons.lock,
              title: context.tr('iam_profile_passphrase_title'),
              subtitle: context.tr('iam_profile_passphrase_sub', [passwordDaysAgo]),
              trailing: Icon(Icons.keyboard_arrow_right, color: p.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityRow extends StatelessWidget {
  const _SecurityRow({required this.icon, required this.title, required this.subtitle, required this.trailing});

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Vx.blue),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: p.ink)),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: p.muted),
                  ),
                ],
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _PmoPreferences extends StatelessWidget {
  const _PmoPreferences({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final op = controller.operational;
    final timezones = [
      ('utc_plus_1', context.tr('iam_profile_tz_madrid')),
      ('utc_0', context.tr('iam_profile_tz_london')),
      ('utc_minus_5', context.tr('iam_profile_tz_new_york')),
    ];
    Widget gap() => const SizedBox(height: 12);
    return VxCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('iam_profile_pmo_prefs'),
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: p.ink),
          ),
          gap(),
          Caption(context.tr('iam_profile_timezone_label')),
          for (final (key, label) in timezones) ...[
            const SizedBox(height: 8),
            Material(
              color: key == op.timezoneKey ? p.blueSoft : p.chip,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => controller.setTimezone(key),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      if (key == op.timezoneKey) ...[
                        const Icon(Icons.check, size: 18, color: Vx.blue),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: p.ink,
                            fontWeight: key == op.timezoneKey ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          gap(),
          Caption(context.tr('iam_profile_methodology_label')),
          const SizedBox(height: 8),
          SegmentedButton<ProfileMethodology>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: ProfileMethodology.hybrid, label: Text(context.tr('iam_profile_methodology_hybrid'))),
              ButtonSegment(
                value: ProfileMethodology.waterfall,
                label: Text(context.tr('iam_profile_methodology_waterfall')),
              ),
            ],
            selected: {op.methodology},
            onSelectionChanged: (s) => controller.setMethodology(s.first),
          ),
          gap(),
          Caption(context.tr('iam_profile_digest_label')),
          const SizedBox(height: 8),
          SegmentedButton<ProfileDigestFrequency>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: ProfileDigestFrequency.daily, label: Text(context.tr('iam_profile_digest_daily'))),
              ButtonSegment(value: ProfileDigestFrequency.weekly, label: Text(context.tr('iam_profile_digest_weekly'))),
            ],
            selected: {op.digest},
            onSelectionChanged: (s) => controller.setDigest(s.first),
          ),
          gap(),
          Row(
            children: [
              const Icon(Icons.dark_mode, color: Vx.blue),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('iam_profile_dark_studio'), style: TextStyle(fontWeight: FontWeight.w600, color: p.ink)),
                      Text(context.tr('iam_profile_dark_studio_sub'), style: TextStyle(fontSize: 12, color: p.muted)),
                    ],
                  ),
                ),
              ),
              Switch(value: op.darkStudioTheme, onChanged: controller.setDarkStudio),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguagePreferences extends StatelessWidget {
  const _LanguagePreferences();

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final settings = AppScope.of(context).settings;
    return VxCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('profile_preferences_title'),
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: p.ink),
          ),
          const SizedBox(height: 12),
          Text(context.tr('profile_preferences_subtitle'), style: TextStyle(fontSize: 12, color: p.muted)),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: 'en',
                label: Semantics(label: context.tr('profile_a11y_language_en'), child: Text(context.tr('profile_language_en'))),
              ),
              ButtonSegment(
                value: 'es',
                label: Semantics(label: context.tr('profile_a11y_language_es'), child: Text(context.tr('profile_language_es'))),
              ),
            ],
            selected: {settings.locale.languageCode},
            onSelectionChanged: (s) => settings.setLocale(Locale(s.first)),
          ),
        ],
      ),
    );
  }
}

class _AccessGovernance extends StatelessWidget {
  const _AccessGovernance({required this.tenantId, required this.auditRecords, required this.onOpenAudit});

  final String tenantId;
  final int auditRecords;
  final VoidCallback onOpenAudit;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return VxCard(
      color: p.blueSoft,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge, color: Vx.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('iam_profile_access_title'),
                  style: TextStyle(fontWeight: FontWeight.w700, color: p.ink),
                ),
              ),
              Pill(context.tr('iam_profile_tier_badge'), bg: p.surface, fg: Vx.blue),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(context.tr('iam_profile_master_role'), style: TextStyle(fontWeight: FontWeight.w600, color: p.ink)),
          ),
          Text(context.tr('iam_profile_master_role_desc'), style: TextStyle(fontSize: 12, color: p.muted)),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(context.tr('iam_profile_suite_version'), style: TextStyle(fontSize: 11, color: p.muted)),
          ),
          Text(tenantId, style: const TextStyle(fontWeight: FontWeight.w700, color: Vx.blue, fontSize: 13)),
          const SizedBox(height: 12),
          Material(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onOpenAudit,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('iam_profile_audit_link'),
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: p.ink),
                      ),
                    ),
                    Text(
                      context.tr('iam_profile_audit_records', [auditRecords]),
                      style: TextStyle(color: p.muted, fontSize: 12),
                    ),
                    Icon(Icons.keyboard_arrow_right, color: p.muted),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
