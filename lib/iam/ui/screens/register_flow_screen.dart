import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/core/ui/motion.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_brand.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_controls.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_widgets.dart';
import 'package:mdeps_flutter/iam/application/iam_controllers.dart';
import 'package:mdeps_flutter/iam/domain/iam_models.dart';
import 'package:mdeps_flutter/iam/ui/widgets/auth_components.dart';

/// Corporate registration wizard: personal → contact → profession → role → done.
class RegisterFlowScreen extends StatefulWidget {
  const RegisterFlowScreen({
    super.key,
    required this.controller,
    required this.onExit,
    required this.onFinished,
  });

  final RegistrationController controller;
  final VoidCallback onExit;
  final VoidCallback onFinished;

  @override
  State<RegisterFlowScreen> createState() => _RegisterFlowScreenState();
}

class _RegisterFlowScreenState extends State<RegisterFlowScreen> {
  RegistrationController get _vm => widget.controller;
  RegistrationStep _previous = RegistrationStep.personal;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onChanged);
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final key = _vm.submitErrorKey;
    if (key != null && mounted) {
      showVxSnack(context, context.tr(key));
      _vm.clearSubmitError();
    }
  }

  void _goBack() {
    if (!_vm.back()) {
      widget.onExit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final step = _vm.step;
        final forward = step.index >= _previous.index;
        _previous = step;
        final titleKey = switch (step) {
          RegistrationStep.personal => 'reg_title_personal',
          RegistrationStep.contact => 'reg_title_contact',
          RegistrationStep.profession => 'reg_title_profession',
          RegistrationStep.role => 'reg_title_role',
          RegistrationStep.done => 'reg_title_done',
        };
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && step != RegistrationStep.done) {
              _goBack();
            }
          },
          child: Scaffold(
            backgroundColor: p.bg,
            body: SafeArea(
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: VxMotion.fast,
                    child: AuthHeader(
                      key: ValueKey(titleKey),
                      title: context.tr(titleKey),
                      onBack: step == RegistrationStep.done ? null : _goBack,
                    ),
                  ),
                  Divider(height: 1, color: p.line),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: AuthStepper(
                      labels: [
                        context.tr('reg_step_personal'),
                        context.tr('reg_step_contact'),
                        context.tr('reg_step_profession'),
                        context.tr('reg_step_role'),
                        context.tr('reg_step_done'),
                      ],
                      currentIndex: step.index,
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: VxMotion.standard,
                      reverseDuration: VxMotion.fast,
                      switchInCurve: VxMotion.easeOut,
                      transitionBuilder: (child, animation) {
                        final isIncoming = child.key == ValueKey(step);
                        final dx = (forward ? 1 : -1) * (isIncoming ? 0.2 : -0.125);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween(begin: Offset(dx, 0), end: Offset.zero)
                                .animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: SingleChildScrollView(
                        key: ValueKey(step),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: switch (step) {
                              RegistrationStep.personal => _PersonalStep(vm: _vm),
                              RegistrationStep.contact => _ContactStep(vm: _vm),
                              RegistrationStep.profession => _ProfessionStep(vm: _vm),
                              RegistrationStep.role => _RoleStep(vm: _vm),
                              RegistrationStep.done => _DoneStep(vm: _vm, onFinished: widget.onFinished),
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String? _error(BuildContext context, RegistrationController vm, RegistrationField field) {
  final key = vm.errors[field];
  return key == null ? null : context.tr(key);
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.text);

  final String? text;

  @override
  Widget build(BuildContext context) {
    if (text == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Text(text!, style: const TextStyle(color: Vx.red, fontSize: 12)),
    );
  }
}

/// Text field bound to a draft value that keeps its own controller.
class _DraftField extends StatefulWidget {
  const _DraftField({
    required this.value,
    required this.onChanged,
    required this.label,
    this.hint,
    this.error,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.textInputAction = TextInputAction.next,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String label;
  final String? hint;
  final String? error;
  final IconData? icon;
  final TextInputType keyboardType;
  final bool isPassword;
  final TextInputAction textInputAction;

  @override
  State<_DraftField> createState() => _DraftFieldState();
}

class _DraftFieldState extends State<_DraftField> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant _DraftField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VxTextField(
      controller: _controller,
      label: widget.label,
      hint: widget.hint,
      error: widget.error,
      leadingIcon: widget.icon,
      keyboardType: widget.keyboardType,
      isPassword: widget.isPassword,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
    );
  }
}

// ───────────────────────── STEP 1 · PERSONAL DETAILS ─────────────────────────

class _PersonalStep extends StatelessWidget {
  const _PersonalStep({required this.vm});

  final RegistrationController vm;

  @override
  Widget build(BuildContext context) {
    final d = vm.draft;
    return _StepCard(
      children: [
        StepIntro(
          eyebrow: context.tr('reg_eyebrow', [1, 4, context.tr('reg_topic_identity')]),
          title: context.tr('reg_personal_heading'),
          description: context.tr('reg_personal_desc'),
        ),
        _DraftField(
          value: d.firstName,
          onChanged: (v) => vm.update((it) => it.copyWith(firstName: v)),
          label: context.tr('reg_first_name'),
          hint: 'Alejandro',
          error: _error(context, vm, RegistrationField.firstName),
        ),
        _DraftField(
          value: d.lastName,
          onChanged: (v) => vm.update((it) => it.copyWith(lastName: v)),
          label: context.tr('reg_last_name'),
          hint: 'Vance Rivas',
          error: _error(context, vm, RegistrationField.lastName),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VxFieldLabel(context.tr('reg_birth_date')),
            Row(
              children: [
                Expanded(
                  flex: 10,
                  child: _DatePartField(
                    value: d.birthDay,
                    hint: context.tr('reg_dd'),
                    maxLength: 2,
                    onChanged: (v) => vm.update((it) => it.copyWith(birthDay: v)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 10,
                  child: _DatePartField(
                    value: d.birthMonth,
                    hint: context.tr('reg_mm'),
                    maxLength: 2,
                    onChanged: (v) => vm.update((it) => it.copyWith(birthMonth: v)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 13,
                  child: _DatePartField(
                    value: d.birthYear,
                    hint: context.tr('reg_yyyy'),
                    maxLength: 4,
                    onChanged: (v) => vm.update((it) => it.copyWith(birthYear: v)),
                  ),
                ),
              ],
            ),
            _ErrorLine(_error(context, vm, RegistrationField.birthDate)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VxFieldLabel(context.tr('reg_salutation')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (value, key) in const [
                  (Salutation.mr, 'reg_salutation_mr'),
                  (Salutation.ms, 'reg_salutation_ms'),
                  (Salutation.unspecified, 'reg_salutation_none'),
                ])
                  VxChoiceChip(
                    text: context.tr(key),
                    selected: d.salutation == value,
                    onTap: () => vm.update((it) => it.copyWith(salutation: value)),
                  ),
              ],
            ),
          ],
        ),
        VxButton(text: context.tr('reg_cta_to_contact'), onPressed: vm.next),
      ],
    );
  }
}

class _DatePartField extends StatefulWidget {
  const _DatePartField({
    required this.value,
    required this.hint,
    required this.maxLength,
    required this.onChanged,
  });

  final String value;
  final String hint;
  final int maxLength;
  final ValueChanged<String> onChanged;

  @override
  State<_DatePartField> createState() => _DatePartFieldState();
}

class _DatePartFieldState extends State<_DatePartField> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(widget.maxLength),
      ],
      onChanged: widget.onChanged,
      cursorColor: p.ink,
      style: TextStyle(color: p.ink, fontSize: 15),
      decoration: vxInputDecoration(context, hint: widget.hint),
    );
  }
}

// ───────────────────────── STEP 2 · CONTACT & ACCESS ─────────────────────────

class _ContactStep extends StatelessWidget {
  const _ContactStep({required this.vm});

  final RegistrationController vm;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final d = vm.draft;
    return _StepCard(
      children: [
        StepIntro(
          eyebrow: context.tr('reg_eyebrow', [2, 4, context.tr('reg_topic_security')]),
          title: context.tr('reg_contact_heading'),
        ),
        VxButton(
          text: context.tr('reg_sso_link'),
          onPressed: () => showVxSnack(context, context.tr('auth_sso_unavailable')),
          style: VxButtonStyle.secondary,
          leadingIcon: Icons.cloud_outlined,
          height: 48,
        ),
        Row(
          children: [
            Expanded(child: Divider(color: p.line)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                context.tr('auth_or_manual'),
                style: TextStyle(fontSize: 11, color: p.muted, fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(child: Divider(color: p.line)),
          ],
        ),
        _DraftField(
          value: d.email,
          onChanged: (v) => vm.update((it) => it.copyWith(email: v)),
          label: context.tr('reg_email'),
          hint: 'alex.vance@enterprise.com',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          error: _error(context, vm, RegistrationField.email),
        ),
        _DraftField(
          value: d.phone,
          onChanged: (v) {
            final clean = v.replaceAll(RegExp(r'[^0-9+ \-]'), '');
            vm.update((it) => it.copyWith(phone: clean.length > 20 ? clean.substring(0, 20) : clean));
          },
          label: context.tr('reg_phone'),
          hint: '+34 612 890 451',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          error: _error(context, vm, RegistrationField.phone),
        ),
        _DraftField(
          value: d.password,
          onChanged: (v) => vm.update((it) => it.copyWith(password: v)),
          label: context.tr('reg_password'),
          icon: Icons.lock,
          isPassword: true,
          error: _error(context, vm, RegistrationField.password),
        ),
        _DraftField(
          value: d.confirmPassword,
          onChanged: (v) => vm.update((it) => it.copyWith(confirmPassword: v)),
          label: context.tr('reg_confirm_password'),
          icon: Icons.lock,
          isPassword: true,
          textInputAction: TextInputAction.done,
          error: _error(context, vm, RegistrationField.confirmPassword),
        ),
        PasswordStrengthMeter(strength: PasswordPolicy.strength(d.password)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => vm.update((it) => it.copyWith(acceptedTerms: !it.acceptedTerms)),
              child: Row(
                children: [
                  Checkbox(
                    value: d.acceptedTerms,
                    activeColor: p.ink,
                    checkColor: p.surface,
                    onChanged: (_) =>
                        vm.update((it) => it.copyWith(acceptedTerms: !it.acceptedTerms)),
                  ),
                  Expanded(
                    child: Text(
                      context.tr('reg_terms'),
                      style: TextStyle(fontSize: 13, color: p.ink, height: 1.38),
                    ),
                  ),
                ],
              ),
            ),
            _ErrorLine(_error(context, vm, RegistrationField.terms)),
          ],
        ),
        VxButton(text: context.tr('reg_cta_to_profession'), onPressed: vm.next),
      ],
    );
  }
}

// ───────────────────────── STEP 3 · PROFESSIONAL PROFILE ─────────────────────────

class _ProfessionStep extends StatelessWidget {
  const _ProfessionStep({required this.vm});

  final RegistrationController vm;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final d = vm.draft;
    return _StepCard(
      children: [
        StepIntro(
          eyebrow: context.tr('reg_eyebrow', [3, 4, context.tr('reg_topic_career')]),
          title: context.tr('reg_profession_heading'),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.account_tree, color: p.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('reg_roles_banner_eyebrow').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: p.muted,
                      ),
                    ),
                    Text(
                      context.tr('reg_roles_banner_title'),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.ink),
                    ),
                    Text(
                      context.tr('reg_roles_banner_desc'),
                      style: TextStyle(fontSize: 12, color: p.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _VxDropdown(
          label: context.tr('reg_position'),
          value: d.position,
          options: context.trArray('reg_positions'),
          error: _error(context, vm, RegistrationField.position),
          onSelect: (v) => vm.update((it) => it.copyWith(position: v)),
        ),
        _VxDropdown(
          label: context.tr('reg_specialty'),
          value: d.specialty,
          options: context.trArray('reg_specialties'),
          error: _error(context, vm, RegistrationField.specialty),
          onSelect: (v) => vm.update((it) => it.copyWith(specialty: v)),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VxFieldLabel(context.tr('reg_experience')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (value, label) in const [
                  (ExperienceRange.y1to3, '1–3'),
                  (ExperienceRange.y4to7, '4–7'),
                  (ExperienceRange.y8to12, '8–12'),
                  (ExperienceRange.y12plus, '+12'),
                ])
                  VxChoiceChip(
                    text: label,
                    selected: d.experience == value,
                    onTap: () => vm.update((it) => it.copyWith(experience: value)),
                  ),
              ],
            ),
            _ErrorLine(_error(context, vm, RegistrationField.experience)),
          ],
        ),
        VxButton(text: context.tr('reg_cta_to_role'), onPressed: vm.next),
      ],
    );
  }
}

class _VxDropdown extends StatelessWidget {
  const _VxDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.error,
    required this.onSelect,
  });

  final String label;
  final String value;
  final List<String> options;
  final String? error;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VxFieldLabel(label),
        LayoutBuilder(
          builder: (context, constraints) => DropdownMenu<String>(
            width: constraints.maxWidth,
            initialSelection: value.isEmpty ? null : value,
            hintText: context.tr('reg_select_placeholder'),
            errorText: error,
            textStyle: TextStyle(color: p.ink, fontSize: 15),
            menuStyle: MenuStyle(backgroundColor: WidgetStatePropertyAll(p.surface)),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: p.surface,
              hintStyle: TextStyle(color: p.muted.withValues(alpha: 0.7)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: p.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: p.ink, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Vx.red),
              ),
            ),
            onSelected: (v) {
              if (v != null) {
                onSelect(v);
              }
            },
            dropdownMenuEntries: [
              for (final option in options)
                DropdownMenuEntry(
                  value: option,
                  label: option,
                  trailingIcon: option == value ? Icon(Icons.check, color: p.ink) : null,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── STEP 4 · ROLE SELECTION ─────────────────────────

class _RoleStep extends StatelessWidget {
  const _RoleStep({required this.vm});

  final RegistrationController vm;

  @override
  Widget build(BuildContext context) {
    final d = vm.draft;
    final error = _error(context, vm, RegistrationField.role);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepIntro(
          eyebrow: context.tr('reg_eyebrow', [4, 4, context.tr('reg_topic_access')]),
          title: context.tr('reg_role_heading'),
          description: context.tr('reg_role_desc'),
        ),
        const SizedBox(height: 14),
        _RoleCard(
          eyebrow: context.tr('reg_role_leader_eyebrow'),
          title: context.tr('reg_role_leader'),
          description: context.tr('reg_role_leader_desc'),
          bullets: [
            context.tr('reg_role_leader_b1'),
            context.tr('reg_role_leader_b2'),
            context.tr('reg_role_leader_b3'),
          ],
          selected: d.role == PmoRole.projectLeader,
          onTap: () => vm.update((it) => it.copyWith(role: PmoRole.projectLeader)),
        ),
        const SizedBox(height: 14),
        _RoleCard(
          eyebrow: context.tr('reg_role_owner_eyebrow'),
          title: context.tr('reg_role_owner'),
          description: context.tr('reg_role_owner_desc'),
          bullets: [
            context.tr('reg_role_owner_b1'),
            context.tr('reg_role_owner_b2'),
            context.tr('reg_role_owner_b3'),
          ],
          selected: d.role == PmoRole.enterpriseOwner,
          onTap: () => vm.update((it) => it.copyWith(role: PmoRole.enterpriseOwner)),
        ),
        if (error != null) ...[
          const SizedBox(height: 14),
          Text(error, style: const TextStyle(color: Vx.red, fontSize: 12)),
        ],
        const SizedBox(height: 14),
        VxButton(
          text: context.tr('reg_cta_finish'),
          onPressed: vm.next,
          loading: vm.isSubmitting,
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.bullets,
    required this.selected,
    required this.onTap,
  });

  final String eyebrow;
  final String title;
  final String description;
  final List<String> bullets;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: PressScale(
        pressedScale: 0.98,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: VxMotion.fast,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: selected ? p.surface : p.chip.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? p.ink : p.line, width: selected ? 2 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eyebrow.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: p.muted,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                color: p.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _RadioDot(selected: selected),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    description,
                    style: TextStyle(fontSize: 13, color: p.muted, height: 1.38),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedOpacity(
                  opacity: selected ? 1 : 0.55,
                  duration: VxMotion.fast,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: p.chip,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < bullets.length; i++) ...[
                          if (i > 0) const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: selected ? p.ink : p.muted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  bullets[i],
                                  style: TextStyle(fontSize: 12, color: p.ink),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
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

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? p.ink : p.gray, width: 2),
      ),
      child: AnimatedScale(
        scale: selected ? 1 : 0.4,
        duration: VxMotion.standard,
        curve: Curves.elasticOut,
        child: AnimatedOpacity(
          opacity: selected ? 1 : 0,
          duration: VxMotion.fast,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: p.ink, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── STEP 5 · SUCCESS ─────────────────────────

class _DoneStep extends StatelessWidget {
  const _DoneStep({required this.vm, required this.onFinished});

  final RegistrationController vm;
  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final d = vm.draft;
    final user = vm.registeredUser;
    final roleLabel = context.tr(
      d.role == PmoRole.enterpriseOwner ? 'reg_role_owner' : 'reg_role_leader',
    );
    final summary = [
      (context.tr('reg_done_user'), user?.name ?? d.fullName),
      (context.tr('reg_done_email'), user?.email ?? d.email),
      (context.tr('reg_done_role'), roleLabel),
      (context.tr('reg_done_space'), context.tr('reg_done_space_value')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.line),
          ),
          child: Column(
            children: [
              const AnimatedSuccessMark(size: 76),
              const SizedBox(height: 14),
              StaggeredEnter(
                index: 0,
                baseDelayMs: 380,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: p.ink,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    context.tr('reg_done_badge').toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: p.surface,
                    ),
                  ),
                ),
              ),
              StaggeredEnter(
                index: 1,
                baseDelayMs: 380,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    context.tr('reg_done_title'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: p.ink),
                  ),
                ),
              ),
              StaggeredEnter(
                index: 2,
                baseDelayMs: 380,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    context.tr('reg_done_desc'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: p.muted),
                  ),
                ),
              ),
              StaggeredEnter(
                index: 3,
                baseDelayMs: 380,
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: p.chip,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr('reg_done_workspace'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: p.ink,
                          ),
                        ),
                      ),
                      LivePill(text: context.tr('reg_done_active')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.chip,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Caption(context.tr('reg_done_summary')),
              for (var i = 0; i < summary.length; i++) ...[
                const SizedBox(height: 10),
                StaggeredEnter(
                  index: i,
                  baseDelayMs: 600,
                  child: _SummaryRow(label: summary[i].$1, value: summary[i].$2),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        StaggeredEnter(
          index: 0,
          baseDelayMs: 820,
          child: VxButton(
            text: context.tr('reg_cta_enter'),
            onPressed: onFinished,
            leadingIcon: Icons.arrow_forward,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(fontSize: 10, color: p.muted, letterSpacing: 0.4),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.ink),
                ),
              ],
            ),
          ),
          const Icon(Icons.check, size: 16, color: Vx.green),
        ],
      ),
    );
  }
}

/// Pill with a "live" dot.
class LivePill extends StatelessWidget {
  const LivePill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(50)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Dot(color: Color(0xFF4ADE80), size: 6),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.surface),
          ),
        ],
      ),
    );
  }
}
