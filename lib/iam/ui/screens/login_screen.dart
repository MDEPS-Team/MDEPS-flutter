import 'package:flutter/material.dart';
import 'package:mdeps_flutter/core/l10n/l10n.dart';
import 'package:mdeps_flutter/core/theme/vx_colors.dart';
import 'package:mdeps_flutter/core/ui/motion.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_brand.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_controls.dart';
import 'package:mdeps_flutter/core/ui/widgets/vx_widgets.dart';
import 'package:mdeps_flutter/iam/application/iam_controllers.dart';
import 'package:mdeps_flutter/iam/ui/widgets/auth_components.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.controller,
    required this.onLoginSuccess,
    required this.onCreateAccount,
    required this.onForgotPassword,
  });

  final IamController controller;
  final VoidCallback onLoginSuccess;
  final VoidCallback onCreateAccount;
  final VoidCallback onForgotPassword;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  IamController get _iam => widget.controller;

  @override
  void initState() {
    super.initState();
    _iam.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _iam.removeListener(_onStateChanged);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    final error = _iam.errorMessage;
    if (error != null && mounted) {
      showVxSnack(context, error);
      _iam.clearError();
    }
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    await _iam.signIn(_email.text, _password.text);
    if (mounted && _iam.isAuthenticated) {
      widget.onLoginSuccess();
    }
  }

  Future<void> _biometric() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => const _BiometricPrompt(),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    showVxSnack(context, context.tr('iam_biometric_success'));
    await _iam.signInWithBiometrics();
    if (mounted && _iam.isAuthenticated) {
      widget.onLoginSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _iam,
          builder: (context, _) {
            final loading = _iam.isLoading;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    children: [
                      const StaggeredEnter(index: 0, child: VxBrandMark(size: 60)),
                      StaggeredEnter(
                        index: 1,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            context.tr('iam_login_title'),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: p.ink,
                            ),
                          ),
                        ),
                      ),
                      StaggeredEnter(
                        index: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            context.tr('auth_tagline').toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.6,
                              color: p.muted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      StaggeredEnter(
                        index: 3,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: p.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: p.line),
                          ),
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  context.tr('auth_welcome_back'),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: p.ink,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    context.tr('auth_welcome_desc'),
                                    style: TextStyle(fontSize: 14, height: 1.43, color: p.muted),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Semantics(
                                  label: context.tr('iam_a11y_corporate_email_field'),
                                  child: VxTextField(
                                    controller: _email,
                                    label: context.tr('iam_login_corporate_email_label'),
                                    hint: 'alex.vance@enterprise.com',
                                    leadingIcon: Icons.email,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    enabled: !loading,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Semantics(
                                  label: context.tr('iam_a11y_password_field'),
                                  child: VxTextField(
                                    controller: _password,
                                    label: context.tr('iam_login_password_label'),
                                    leadingIcon: Icons.lock,
                                    isPassword: true,
                                    autofillHints: const [AutofillHints.password],
                                    enabled: !loading,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _signIn(),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: AuthLink(
                                    text: context.tr('auth_forgot_password'),
                                    onTap: widget.onForgotPassword,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Semantics(
                                        label: context.tr('iam_a11y_sign_in_button'),
                                        child: VxButton(
                                          text: context.tr('iam_login_sign_in'),
                                          onPressed: _signIn,
                                          loading: loading,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    AuthTile(
                                      width: 52,
                                      height: 52,
                                      padding: EdgeInsets.zero,
                                      color: p.chip,
                                      enabled: !loading,
                                      semanticLabel: context.tr('iam_a11y_biometric_button'),
                                      onTap: _biometric,
                                      child: Icon(Icons.fingerprint, size: 26, color: p.ink),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: p.line)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Text(
                                        context.tr('auth_or_continue'),
                                        style: TextStyle(fontSize: 11, color: p.muted),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: p.line)),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    for (final (short, a11y, icon) in const [
                                      ('auth_sso_microsoft_short', 'auth_sso_microsoft', Icons.window_outlined),
                                      ('auth_sso_google_short', 'auth_sso_google', Icons.cloud_outlined),
                                      ('auth_sso_apple_short', 'auth_sso_apple', Icons.phone_iphone_outlined),
                                    ]) ...[
                                      if (short != 'auth_sso_microsoft_short') const SizedBox(width: 8),
                                      Expanded(
                                        child: AuthTile(
                                          semanticLabel: context.tr(a11y),
                                          enabled: !loading,
                                          onTap: () => showVxSnack(
                                            context,
                                            context.tr('auth_sso_unavailable'),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(icon, size: 20, color: p.ink),
                                              const SizedBox(height: 4),
                                              Text(
                                                context.tr(short),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: p.ink,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      StaggeredEnter(
                        index: 4,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 18),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            alignment: WrapAlignment.center,
                            children: [
                              Text(
                                context.tr('auth_no_account'),
                                style: TextStyle(fontSize: 13, color: p.muted),
                              ),
                              AuthLink(
                                text: context.tr('auth_create_account'),
                                onTap: widget.onCreateAccount,
                                bold: true,
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
          },
        ),
      ),
    );
  }
}

/// Simulated system biometric prompt (the mock IAM has no real sensor).
class _BiometricPrompt extends StatelessWidget {
  const _BiometricPrompt();

  @override
  Widget build(BuildContext context) {
    final p = context.vx;
    return AlertDialog(
      title: Text(context.tr('iam_biometric_title')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.tr('iam_biometric_subtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(color: p.muted),
          ),
          const SizedBox(height: 20),
          Semantics(
            button: true,
            label: context.tr('iam_biometric_sign_in_action'),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(true),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: p.blueSoft, shape: BoxShape.circle),
                child: const Icon(Icons.fingerprint, size: 40, color: Vx.blue),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.tr('iam_biometric_cancel')),
        ),
      ],
    );
  }
}
