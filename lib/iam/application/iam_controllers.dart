import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mdeps_flutter/iam/data/in_memory_auth_repository.dart';
import 'package:mdeps_flutter/iam/domain/iam_models.dart';

/// Session state for the sign-in screen and the authenticated shell.
class IamController extends ChangeNotifier {
  IamController(this._repository) {
    _repository.addListener(_onRepositoryChanged);
  }

  final InMemoryAuthRepository _repository;

  bool isLoading = false;
  bool isAuthenticated = false;
  String? errorMessage;

  User? get user => _repository.currentUser;

  void _onRepositoryChanged() => notifyListeners();

  Future<void> signIn(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final user = await _repository.login(
        Credentials(email: email.trim(), password: password),
      );
      await _persistSession(user);
      isAuthenticated = true;
    } on Object catch (error) {
      isAuthenticated = false;
      errorMessage = error is ArgumentError ? '${error.message}' : 'Sign in failed.';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> signInWithBiometrics() async {
    await signIn('biometric@vantage.internal', 'biometric-gate');
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  /// Clears the session flag without deleting the stored profile.
  Future<void> endActiveSession() async {
    await _repository.clearSession();
    isAuthenticated = false;
    isLoading = false;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> saveProfileAvatar(String path) => _repository.saveProfileAvatar(path);

  Future<void> _persistSession(User user) async {
    await _repository.saveUserProfile(user);
    await _repository.saveToken(
      Token(accessToken: 'mock-access-${user.id}', refreshToken: 'mock-refresh-${user.id}'),
    );
  }

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryChanged);
    super.dispose();
  }
}

enum RegistrationStep { personal, contact, profession, role, done }

enum RegistrationField {
  firstName,
  lastName,
  birthDate,
  email,
  phone,
  password,
  confirmPassword,
  terms,
  position,
  specialty,
  experience,
  role,
}

/// Multi-step corporate registration wizard.
class RegistrationController extends ChangeNotifier {
  RegistrationController(this._repository);

  final AuthRepository _repository;

  RegistrationStep step = RegistrationStep.personal;
  RegistrationDraft draft = const RegistrationDraft();

  /// Field → string key of the error message.
  Map<RegistrationField, String> errors = const {};
  bool isSubmitting = false;
  String? submitErrorKey;
  User? registeredUser;

  void update(RegistrationDraft Function(RegistrationDraft) transform) {
    draft = transform(draft);
    // Clear errors of the fields the user is correcting.
    final stillInvalid = _validate(step, draft).keys.toSet();
    errors = {
      for (final e in errors.entries)
        if (stillInvalid.contains(e.key)) e.key: e.value,
    };
    notifyListeners();
  }

  /// Tries to advance; exposes errors and stays on the step if invalid.
  void next() {
    final found = _validate(step, draft);
    if (found.isNotEmpty) {
      errors = found;
      notifyListeners();
      return;
    }
    switch (step) {
      case RegistrationStep.personal:
        _goTo(RegistrationStep.contact);
      case RegistrationStep.contact:
        _goTo(RegistrationStep.profession);
      case RegistrationStep.profession:
        _goTo(RegistrationStep.role);
      case RegistrationStep.role:
        _submit();
      case RegistrationStep.done:
        break;
    }
  }

  /// Returns false when already on the first step (UI must exit the flow).
  bool back() {
    final previous = switch (step) {
      RegistrationStep.personal || RegistrationStep.done => null,
      RegistrationStep.contact => RegistrationStep.personal,
      RegistrationStep.profession => RegistrationStep.contact,
      RegistrationStep.role => RegistrationStep.profession,
    };
    if (previous == null) {
      return false;
    }
    _goTo(previous);
    return true;
  }

  void clearSubmitError() {
    submitErrorKey = null;
    notifyListeners();
  }

  void _goTo(RegistrationStep target) {
    step = target;
    errors = const {};
    notifyListeners();
  }

  Future<void> _submit() async {
    if (isSubmitting) {
      return;
    }
    isSubmitting = true;
    submitErrorKey = null;
    notifyListeners();
    try {
      final user = await _repository.register(draft);
      await _repository.saveUserProfile(user);
      await _repository.saveToken(
        Token(accessToken: 'mock-access-${user.id}', refreshToken: 'mock-refresh-${user.id}'),
      );
      registeredUser = user;
      step = RegistrationStep.done;
    } on Object {
      submitErrorKey = 'reg_error_submit';
    }
    isSubmitting = false;
    notifyListeners();
  }

  Map<RegistrationField, String> _validate(RegistrationStep step, RegistrationDraft d) {
    final out = <RegistrationField, String>{};
    switch (step) {
      case RegistrationStep.personal:
        if (d.firstName.trim().isEmpty) out[RegistrationField.firstName] = 'reg_error_required';
        if (d.lastName.trim().isEmpty) out[RegistrationField.lastName] = 'reg_error_required';
        if (!_isValidBirthDate(d)) out[RegistrationField.birthDate] = 'reg_error_birth_date';
      case RegistrationStep.contact:
        if (!EmailPolicy.isValid(d.email)) out[RegistrationField.email] = 'reg_error_email';
        if (RegExp(r'\d').allMatches(d.phone).length < 7) {
          out[RegistrationField.phone] = 'reg_error_phone';
        }
        if (!PasswordPolicy.isAcceptable(d.password)) {
          out[RegistrationField.password] = 'reg_error_password_weak';
        }
        if (d.confirmPassword != d.password || d.confirmPassword.isEmpty) {
          out[RegistrationField.confirmPassword] = 'reg_error_password_mismatch';
        }
        if (!d.acceptedTerms) out[RegistrationField.terms] = 'reg_error_terms';
      case RegistrationStep.profession:
        if (d.position.trim().isEmpty) out[RegistrationField.position] = 'reg_error_required';
        if (d.specialty.trim().isEmpty) out[RegistrationField.specialty] = 'reg_error_required';
        if (d.experience == null) out[RegistrationField.experience] = 'reg_error_required';
      case RegistrationStep.role:
        if (d.role == null) out[RegistrationField.role] = 'reg_error_role';
      case RegistrationStep.done:
        break;
    }
    return out;
  }

  bool _isValidBirthDate(RegistrationDraft d) {
    final day = int.tryParse(d.birthDay);
    final month = int.tryParse(d.birthMonth);
    final year = int.tryParse(d.birthYear);
    if (day == null || month == null || year == null) {
      return false;
    }
    if (month < 1 || month > 12 || day < 1 || year < 1900) {
      return false;
    }
    final date = DateTime(year, month, day);
    if (date.month != month || date.day != day) {
      return false; // e.g. 31 Feb rolled over
    }
    final now = DateTime.now();
    final limit = DateTime(now.year - 16, now.month, now.day);
    return date.isBefore(limit);
  }
}

enum RecoveryStep { email, code, newPassword, done }

/// Password recovery: email → 6-digit code → new password → done.
class PasswordRecoveryController extends ChangeNotifier {
  PasswordRecoveryController(this._repository);

  final AuthRepository _repository;
  static const resendSeconds = 30;
  final int codeLength = InMemoryAuthRepository.resetCodeLength;

  RecoveryStep step = RecoveryStep.email;
  String email = '';
  String code = '';
  String newPassword = '';
  String confirmPassword = '';
  bool isLoading = false;
  String? errorKey;
  int resendSecondsLeft = 0;
  Timer? _countdown;

  void onEmailChange(String value) {
    email = value;
    errorKey = null;
    notifyListeners();
  }

  void onCodeChange(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    code = digits.length > codeLength ? digits.substring(0, codeLength) : digits;
    errorKey = null;
    notifyListeners();
    if (code.length == codeLength) {
      verifyCode();
    }
  }

  void onNewPasswordChange(String value) {
    newPassword = value;
    errorKey = null;
    notifyListeners();
  }

  void onConfirmPasswordChange(String value) {
    confirmPassword = value;
    errorKey = null;
    notifyListeners();
  }

  Future<void> sendCode() async {
    if (!EmailPolicy.isValid(email)) {
      errorKey = 'reg_error_email';
      notifyListeners();
      return;
    }
    await _request(() async {
      await _repository.requestPasswordReset(email.trim());
      step = RecoveryStep.code;
      code = '';
      _startCountdown();
    });
  }

  Future<void> resendCode() async {
    if (resendSecondsLeft > 0) {
      return;
    }
    await _request(() async {
      await _repository.requestPasswordReset(email.trim());
      code = '';
      _startCountdown();
    });
  }

  Future<void> verifyCode() async {
    if (isLoading) {
      return;
    }
    if (code.length != codeLength) {
      errorKey = 'rec_error_code';
      notifyListeners();
      return;
    }
    await _request(
      () async {
        await _repository.verifyResetCode(email.trim(), code);
        step = RecoveryStep.newPassword;
      },
      errorKey: 'rec_error_code',
    );
  }

  Future<void> savePassword() async {
    if (!PasswordPolicy.isAcceptable(newPassword)) {
      errorKey = 'reg_error_password_weak';
      notifyListeners();
      return;
    }
    if (newPassword != confirmPassword) {
      errorKey = 'reg_error_password_mismatch';
      notifyListeners();
      return;
    }
    await _request(() async {
      await _repository.resetPassword(email.trim(), code, newPassword);
      step = RecoveryStep.done;
    });
  }

  /// Returns false when the flow must be exited.
  bool back() {
    final previous = switch (step) {
      RecoveryStep.email || RecoveryStep.done => null,
      RecoveryStep.code => RecoveryStep.email,
      RecoveryStep.newPassword => RecoveryStep.code,
    };
    if (previous == null) {
      return false;
    }
    step = previous;
    errorKey = null;
    notifyListeners();
    return true;
  }

  void _startCountdown() {
    _countdown?.cancel();
    resendSecondsLeft = resendSeconds;
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      resendSecondsLeft = (resendSecondsLeft - 1).clamp(0, resendSeconds);
      if (resendSecondsLeft == 0) {
        timer.cancel();
      }
      notifyListeners();
    });
  }

  Future<void> _request(Future<void> Function() block, {String errorKey = 'rec_error_generic'}) async {
    isLoading = true;
    this.errorKey = null;
    notifyListeners();
    try {
      await block();
    } on Object {
      this.errorKey = errorKey;
    }
    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }
}
