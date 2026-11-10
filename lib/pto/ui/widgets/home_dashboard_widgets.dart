import 'package:flutter/material.dart';
import 'package:mdeps_flutter/ass/application/analytics_controller.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/core/ui/motion.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_widgets.dart';
import 'package:mdeps_flutter/gro/ui/gro_ui_extensions.dart';
import 'package:mdeps_flutter/pto/application/pto_controllers.dart';
import 'package:mdeps_flutter/pto/ui/pto_ui_extensions.dart';

const _amber = Color(0xFFB7791F);

/// Accent readable in both themes (in dark the primary is lighter than Vx.blue).
Color _accent(BuildContext context) => Theme.of(context).colorScheme.primary;

// ───────────────────────── GREETING ─────────────────────────

class HomeGreeting extends StatelessWidget {
  const HomeGreeting({
    super.key,
    required this.userName,
    required this.userRole,
    required this.efficiencyPercent,
  });

  final String? userName;
  final String? userRole;
  final int efficiencyPercent;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final first = userName?.trim().split(' ').first;
    final firstName = (first == null || first.isEmpty) ? context.tr('home_greeting_fallback_name') : first;
    final role = (userRole == null || userRole!.trim().isEmpty)
        ? context.tr('home_greeting_fallback_name')
        : userRole!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(50)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: p.muted),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        context.formatLongToday(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: p.ink, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: p.greenSoft, borderRadius: BorderRadius.circular(50)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Dot(color: Vx.green, size: 6),
                  const SizedBox(width: 6),
                  Text(
                    context.tr('home_efficiency_pill', [efficiencyPercent]),
                    style: const TextStyle(fontSize: 12, color: Vx.green, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Text(
            context.tr('home_hello', [firstName]),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: p.ink,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            context.tr('home_role_line', [role]),
            style: TextStyle(fontSize: 13, color: p.muted),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── QUICK ACTIONS ─────────────────────────

class HomeActionChips extends StatelessWidget {
  const HomeActionChips({
    super.key,
    required this.onNewProject,
    required this.onRegisterMilestone,
    required this.onOpenKanban,
    required this.onOpenAnalytics,
  });

  final VoidCallback onNewProject;
  final VoidCallback onRegisterMilestone;
  final VoidCallback onOpenKanban;
  final VoidCallback onOpenAnalytics;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ActionChip(context.tr('home_action_new_project'), Icons.add, true, onNewProject),
          const SizedBox(width: 8),
          _ActionChip(context.tr('home_action_kanban'), Icons.view_column_outlined, false, onOpenKanban),
          const SizedBox(width: 8),
          _ActionChip(context.tr('home_action_milestone'), Icons.flag, false, onRegisterMilestone),
          const SizedBox(width: 8),
          _ActionChip(context.tr('home_action_analytics'), Icons.analytics, false, onOpenAnalytics),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip(this.text, this.icon, this.primary, this.onTap);

  final String text;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final fg = primary ? Colors.white : p.ink;
    return PressScale(
      pressedScale: 0.96,
      child: Material(
        color: primary ? Vx.blue : p.surface,
        shape: StadiumBorder(side: primary ? BorderSide.none : BorderSide(color: p.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
                Text(text, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── PRIORITY ALERT ─────────────────────────

class PriorityAlertCard extends StatelessWidget {
  const PriorityAlertCard({
    super.key,
    required this.alert,
    required this.onManage,
    required this.onAllClear,
  });

  final ProjectRiskAlert? alert;
  final ValueChanged<int> onManage;
  final VoidCallback onAllClear;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final a = alert;
    final hasAlert = a != null;
    final accent = hasAlert ? Vx.red : Vx.green;
    final accentSoft = hasAlert ? p.redSoft : p.greenSoft;
    final link = _accent(context);

    return PressScale(
      pressedScale: 0.985,
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: p.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => a != null ? onManage(a.projectId) : onAllClear(),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [accent.withValues(alpha: 0.10), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconBadge(
                          icon: hasAlert ? Icons.warning_amber : Icons.task_alt,
                          size: 30,
                          iconSize: 17,
                          bg: accentSoft,
                          fg: accent,
                          radius: 9,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Caption(context.tr(hasAlert ? 'home_alert_eyebrow' : 'home_alert_clear_eyebrow')),
                        ),
                        if (a != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(color: p.redSoft, borderRadius: BorderRadius.circular(50)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const PulsingDot(color: Vx.red),
                                const SizedBox(width: 6),
                                Text(
                                  context.tr('home_alert_blockers', [a.activeHighRiskCount]),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Vx.red),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        a != null ? context.tr('home_alert_title', [a.projectName]) : context.tr('home_alert_clear_title'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.ink),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        context.tr(hasAlert ? 'home_alert_desc' : 'home_alert_clear_desc'),
                        style: TextStyle(fontSize: 13, height: 1.38, color: p.muted),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 15, color: link),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            context.tr(hasAlert ? 'home_alert_when' : 'home_alert_clear_when'),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: link),
                          ),
                        ),
                        Text(
                          context.tr(hasAlert ? 'home_alert_manage' : 'home_alert_clear_cta'),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: link),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 15, color: link),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A dot that "beats": slow halo pulse, only on indicators asking for attention.
class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key, required this.color});

  final Color color;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!VxMotion.reduced(context) && !_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = VxMotion.reduced(context);
    return SizedBox(
      width: 12,
      height: 12,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!reduced)
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Transform.scale(
                scale: 0.5 + _c.value * 0.6,
                child: Opacity(
                  opacity: (1 - _c.value) * 0.5,
                  child: Dot(color: widget.color, size: 12),
                ),
              ),
            ),
          Dot(color: widget.color, size: 6),
        ],
      ),
    );
  }
}

// ───────────────────────── METRICS ─────────────────────────

enum MetricTone { neutral, good, warn, bad }

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.iconTint,
    required this.iconBg,
    required this.value,
    required this.valueSuffix,
    required this.label,
    required this.caption,
    required this.captionTone,
    required this.onTap,
    this.tag,
  });

  final IconData icon;
  final Color iconTint;
  final Color iconBg;
  final int value;
  final String valueSuffix;
  final String label;
  final String caption;
  final MetricTone captionTone;
  final String? tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final toneColor = switch (captionTone) {
      MetricTone.neutral => p.muted,
      MetricTone.good => Vx.green,
      MetricTone.warn => _amber,
      MetricTone.bad => Vx.red,
    };
    return PressScale(
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconBadge(icon: icon, size: 34, iconSize: 18, bg: iconBg, fg: iconTint),
                    const Spacer(),
                    if (tag != null)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            tag!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: p.muted),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    CountUpText(value: value),
                    if (valueSuffix.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(
                          valueSuffix,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.muted),
                        ),
                      ),
                  ],
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.ink),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: toneColor, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Number that counts up from 0 the first time (700ms ease-out); later
/// changes animate from the previous value.
class CountUpText extends StatefulWidget {
  const CountUpText({super.key, required this.value, this.style});

  final int value;
  final TextStyle? style;

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText> {
  bool _played = false;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final reduced = VxMotion.reduced(context);
    final duration = reduced ? Duration.zero : Duration(milliseconds: _played ? 300 : 700);
    final begin = _played || reduced ? widget.value.toDouble() : 0.0;
    _played = true;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: widget.value.toDouble()),
      duration: duration,
      curve: VxMotion.easeOut,
      builder: (context, v, _) => Text(
        '${v.toInt()}',
        style: widget.style ??
            TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: p.ink,
            ),
      ),
    );
  }
}

// ───────────────────────── SECTION HEADERS ─────────────────────────

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.eyebrow,
    this.title,
    this.actionLabel,
    this.onAction,
  });

  final String eyebrow;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: p.muted,
                  ),
                ),
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      title!,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.ink),
                    ),
                  ),
              ],
            ),
          ),
          if (actionLabel != null)
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: onAction != null ? _accent(context) : p.muted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────── GOVERNANCE AGENDA ─────────────────────────

class GovernanceAgenda extends StatelessWidget {
  const GovernanceAgenda({super.key, required this.items, required this.onOpen});

  final List<UpcomingMilestone> items;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            () {
              final item = items[i];
              final date = item.milestone.targetDate;
              final overdue = date.isBefore(today);
              final dotColor = overdue ? Vx.red : (i == 0 ? _accent(context) : p.gray);
              final formatted = context.formatMediumDate(date);
              return InkWell(
                onTap: () => onOpen(item.milestone.projectId),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 14,
                          child: Column(
                            children: [
                              Container(width: 2, height: 14, color: i == 0 ? Colors.transparent : p.line),
                              Dot(color: dotColor, size: 10),
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: i == items.length - 1 ? Colors.transparent : p.line,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        overdue ? context.tr('home_agenda_overdue', [formatted]) : formatted,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: overdue ? Vx.red : _accent(context),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: p.chip,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.projectName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: p.muted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(
                                    item.milestone.displayTitle(context),
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.ink),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }(),
        ],
      ),
    );
  }
}

// ───────────────────────── EMPTY STATE ─────────────────────────

class HomeEmptyCard extends StatelessWidget {
  const HomeEmptyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line),
      ),
      child: Column(
        children: [
          IconBadge(icon: icon, size: 44, iconSize: 24, bg: p.blueSoft, fg: _accent(context), radius: 12),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.ink)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: p.muted),
            ),
          ),
          if (actionLabel != null && onAction != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Material(
                color: Vx.blue,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: onAction,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    child: Text(
                      actionLabel!,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
