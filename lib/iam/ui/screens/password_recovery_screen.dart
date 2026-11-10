import 'package:flutter/foundation.dart';
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

/// Password recovery: email → 6-digit code → new password → success.
class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({
    super.key,
    required this.controller,
    required this.entering,
    required this.onExit,
    required this.onEnterApp,
  });

  final PasswordRecoveryController controller;
  final bool entering;
  final VoidCallback onExit;
  final void Function(String email, String password) onEnterApp;

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  PasswordRecoveryController get _vm => widget.controller;
  RecoveryStep _previous = RecoveryStep.email;
  final _email = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  bool _signOutOthers = true;

  @override
  void dispose() {
    _email.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
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
          RecoveryStep.email => 'rec_title_email',
          RecoveryStep.code => 'rec_title_code',
          RecoveryStep.newPassword => 'rec_title_password',
          RecoveryStep.done => 'rec_title_done',
        };
        final error = _vm.errorKey == null ? null : context.tr(_vm.errorKey!);

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              step == RecoveryStep.done ? widget.onExit() : _goBack();
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
                      onBack: step == RecoveryStep.done ? widget.onExit : _goBack,
                    ),
                  ),
                  Divider(height: 1, color: p.line),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: AuthStepper(
                      labels: [
                        context.tr('rec_step_email'),
                        context.tr('rec_step_code'),
                        context.tr('rec_step_password'),
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
                              RecoveryStep.email => _emailStep(context, error),
                              RecoveryStep.code => _codeStep(context, error),
                              RecoveryStep.newPassword => _passwordStep(context, error),
                              RecoveryStep.done => _doneStep(context),
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

  Widget _emailStep(BuildContext context, String? error) {
    return _RecoveryCard(
      children: [
        const Center(child: _SoftBadge(icon: Icons.lock_reset)),
        _CenteredIntro(
          title: context.tr('rec_email_heading'),
          description: context.tr('rec_email_desc'),
        ),
        VxButton(
          text: context.tr('rec_sso'),
          onPressed: () => showVxSnack(context, context.tr('auth_sso_unavailable')),
          style: VxButtonStyle.secondary,
          leadingIcon: Icons.cloud_outlined,
          height: 48,
        ),
        VxTextField(
          controller: _email,
          label: context.tr('rec_email_label'),
          hint: 'alex.vance@enterprise.com',
          leadingIcon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.send,
          error: error,
          onChanged: _vm.onEmailChange,
          onSubmitted: (_) => _vm.sendCode(),
        ),
        VxButton(
          text: context.tr('rec_send_code'),
          onPressed: _vm.sendCode,
          loading: _vm.isLoading,
        ),
        _TextLink(text: context.tr('rec_remembered'), onTap: widget.onExit),
      ],
    );
  }

  Widget _codeStep(BuildContext context, String? error) {
    final p = context.vx;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RecoveryCard(
          children: [
            Caption(context.tr('rec_code_eyebrow')),
            Text(
              context.tr('rec_code_heading'),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: p.ink),
            ),
            Text(
              context.tr('rec_code_desc', [_vm.email.trim()]),
              style: TextStyle(fontSize: 14, color: p.muted, height: 1.43),
            ),
            _OtpInput(
              value: _vm.code,
              length: _vm.codeLength,
              isError: error != null,
              onChanged: _vm.onCodeChange,
            ),
            if (error != null) Text(error, style: const TextStyle(color: Vx.red, fontSize: 12)),
            _ResendRow(secondsLeft: _vm.resendSecondsLeft, onResend: _vm.resendCode),
            VxButton(
              text: context.tr('rec_verify'),
              onPressed: _vm.verifyCode,
              loading: _vm.isLoading,
            ),
            _TextLink(
              text: context.tr('rec_sms'),
              onTap: () => showVxSnack(context, context.tr('rec_sms_unavailable')),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.chip,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('rec_support_title'),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.ink),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('rec_support_desc'),
                style: TextStyle(fontSize: 12, color: p.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _passwordStep(BuildContext context, String? error) {
    final p = context.vx;
    return _RecoveryCard(
      children: [
        const Align(alignment: Alignment.centerLeft, child: _SoftBadge(icon: Icons.shield_outlined)),
        Text(
          context.tr('rec_password_heading'),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: p.ink),
        ),
        Text(context.tr('rec_password_desc'), style: TextStyle(fontSize: 13, color: p.muted)),
        VxTextField(
          controller: _newPassword,
          label: context.tr('rec_new_password'),
          leadingIcon: Icons.lock,
          isPassword: true,
          onChanged: _vm.onNewPasswordChange,
        ),
        _PasswordChecklist(password: _vm.newPassword),
        VxTextField(
          controller: _confirm,
          label: context.tr('rec_confirm_password'),
          leadingIcon: Icons.lock,
          isPassword: true,
          textInputAction: TextInputAction.done,
          error: error,
          onChanged: _vm.onConfirmPasswordChange,
          onSubmitted: (_) => _vm.savePassword(),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _signOutOthers = !_signOutOthers),
          child: Row(
            children: [
              Checkbox(
                value: _signOutOthers,
                activeColor: p.ink,
                checkColor: p.surface,
                onChanged: (v) => setState(() => _signOutOthers = v ?? false),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('rec_sign_out_all'),
                      style: TextStyle(fontSize: 13, color: p.ink),
                    ),
                    Text(
                      context.tr('rec_sign_out_all_desc'),
                      style: TextStyle(fontSize: 12, color: p.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        VxButton(
          text: context.tr('rec_update_password'),
          onPressed: _vm.savePassword,
          loading: _vm.isLoading,
        ),
      ],
    );
  }

  Widget _doneStep(BuildContext context) {
    final p = context.vx;
    return _RecoveryCard(
      children: [
        const Center(child: AnimatedSuccessMark(size: 72)),
        Center(
          child: StaggeredEnter(
            index: 0,
            baseDelayMs: 380,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(50)),
              child: Text(
                context.tr('rec_done_badge').toUpperCase(),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.surface),
              ),
            ),
          ),
        ),
        StaggeredEnter(
          index: 1,
          baseDelayMs: 380,
          child: _CenteredIntro(
            title: context.tr('rec_done_heading'),
            description: context.tr('rec_done_desc'),
          ),
        ),
        const StaggeredEnter(index: 2, baseDelayMs: 380, child: _SecurityLog()),
        StaggeredEnter(
          index: 3,
          baseDelayMs: 380,
          child: VxButton(
            text: context.tr('rec_enter'),
            onPressed: () => widget.onEnterApp(_vm.email.trim(), _vm.newPassword),
            loading: widget.entering,
            leadingIcon: Icons.arrow_forward,
          ),
        ),
        StaggeredEnter(
          index: 4,
          baseDelayMs: 380,
          child: VxButton(
            text: context.tr('rec_back_to_login'),
            onPressed: widget.onExit,
            style: VxButtonStyle.secondary,
          ),
        ),
      ],
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  const _RecoveryCard({required this.children});

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
            if (i > 0) const SizedBox(height: 14),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SoftBadge extends StatelessWidget {
  const _SoftBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, size: 26, color: p.ink),
    );
  }
}

class _CenteredIntro extends StatelessWidget {
  const _CenteredIntro({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: p.ink),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: p.muted, height: 1.46),
        ),
      ],
    );
  }
}

class _TextLink extends StatelessWidget {
  const _TextLink({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: context.vx.muted, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

/// Six boxes over a single hidden text field: pasting the whole code works.
class _OtpInput extends StatefulWidget {
  const _OtpInput({
    required this.value,
    required this.length,
    required this.isError,
    required this.onChanged,
  });

  final String value;
  final int length;
  final bool isError;
  final ValueChanged<String> onChanged;

  @override
  State<_OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<_OtpInput> with SingleTickerProviderStateMixin {
  late final _controller = TextEditingController(text: widget.value);
  final _focus = FocusNode();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focus.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _OtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
    if (widget.isError && !oldWidget.isError && !VxMotion.reduced(context)) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _shake.dispose();
    super.dispose();
  }

  double _shakeOffset(double t) {
    const keys = [0.0, 10.0, -8.0, 6.0, -4.0, 0.0];
    final pos = t * (keys.length - 1);
    final i = pos.floor().clamp(0, keys.length - 2);
    return keys[i] + (keys[i + 1] - keys[i]) * (pos - i);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) => Transform.translate(
        offset: Offset(_shakeOffset(_shake.value), 0),
        child: child,
      ),
      child: GestureDetector(
        onTap: _focus.requestFocus,
        child: Stack(
          children: [
            Row(
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _box(context, p, i)),
                ],
              ],
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  showCursor: false,
                  enableInteractiveSelection: false,
                  onChanged: widget.onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(BuildContext context, VxPalette p, int i) {
    final char = i < widget.value.length ? widget.value[i] : '';
    final isCurrent = i == widget.value.length;
    final borderColor = widget.isError
        ? Vx.red
        : isCurrent
            ? p.ink
            : char.isNotEmpty
                ? p.gray
                : p.line;
    return AspectRatio(
      aspectRatio: 0.82,
      child: AnimatedContainer(
        duration: VxMotion.fast,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: char.isEmpty ? p.chip.withValues(alpha: 0.5) : p.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
        ),
        child: AnimatedSwitcher(
          duration: VxMotion.fast,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: 0.7, end: 1.0)
                  .animate(CurvedAnimation(parent: animation, curve: VxMotion.easeOut)),
              child: child,
            ),
          ),
          child: Text(
            char.isEmpty ? '•' : char,
            key: ValueKey(char),
            style: TextStyle(
              fontSize: char.isEmpty ? 14 : 22,
              fontWeight: FontWeight.w700,
              color: char.isEmpty ? p.gray : p.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResendRow extends StatelessWidget {
  const _ResendRow({required this.secondsLeft, required this.onResend});

  final int secondsLeft;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    String two(int n) => n.toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              secondsLeft > 0
                  ? context.tr('rec_resend_in', [two(secondsLeft ~/ 60), two(secondsLeft % 60)])
                  : context.tr('rec_resend_ready'),
              style: TextStyle(fontSize: 12, color: p.ink),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: secondsLeft == 0 ? onResend : null,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                context.tr('rec_resend_now'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: secondsLeft == 0 ? p.ink : p.muted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordChecklist extends StatelessWidget {
  const _PasswordChecklist({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final hasCase = password.contains(RegExp('[A-Z]')) &&
        password.contains(RegExp('[a-z]')) &&
        password.contains(RegExp(r'\d'));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PasswordStrengthMeter(strength: PasswordPolicy.strength(password)),
          const SizedBox(height: 8),
          _ChecklistItem(
            text: context.tr('rec_rule_length'),
            met: password.length >= PasswordPolicy.minLength,
          ),
          const SizedBox(height: 6),
          _ChecklistItem(text: context.tr('rec_rule_case'), met: hasCase),
          const SizedBox(height: 6),
          _ChecklistItem(
            text: context.tr('rec_rule_symbol'),
            met: password.contains(RegExp(r'[^A-Za-z0-9]')),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({required this.text, required this.met});

  final String text;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Row(
      children: [
        AnimatedSwitcher(
          duration: VxMotion.fast,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: Tween(begin: 0.6, end: 1.0).animate(animation), child: child),
          ),
          child: Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            key: ValueKey(met),
            size: 16,
            color: met ? Vx.green : p.muted,
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 12, color: met ? p.ink : p.muted)),
      ],
    );
  }
}

class _SecurityLog extends StatelessWidget {
  const _SecurityLog();

  String _device(BuildContext context) {
    if (kIsWeb) {
      return 'Web browser';
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'iPhone',
      TargetPlatform.android => 'Android device',
      TargetPlatform.macOS => 'Mac',
      TargetPlatform.windows => 'Windows PC',
      _ => 'Device',
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    final now = TimeOfDay.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Caption(context.tr('rec_log_title')),
          const SizedBox(height: 6),
          _LogRow(icon: Icons.phone_android, text: _device(context)),
          const SizedBox(height: 6),
          _LogRow(icon: Icons.lock, text: context.tr('rec_log_time', [time])),
          const SizedBox(height: 6),
          _LogRow(icon: Icons.shield_outlined, text: context.tr('rec_log_protocol')),
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Row(
      children: [
        Icon(icon, size: 14, color: p.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.ink),
          ),
        ),
      ],
    );
  }
}
