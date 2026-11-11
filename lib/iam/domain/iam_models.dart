class Credentials {
  const Credentials({required this.email, required this.password});

  final String email;
  final String password;
}

class Token {
  const Token({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

class User {
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarPath,
  });

  final String id;
  final String email;
  final String name;
  final String role;
  final String? avatarPath;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  User copyWith({String? email, String? name, String? role, String? avatarPath}) {
    return User(
      id: id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }
}

enum Salutation { mr, ms, unspecified }

enum ExperienceRange { y1to3, y4to7, y8to12, y12plus }

enum PmoRole { projectLeader, enterpriseOwner }

enum PasswordStrength { none, weak, medium, strong }

/// Data accumulated across the registration steps.
class RegistrationDraft {
  const RegistrationDraft({
    this.firstName = '',
    this.lastName = '',
    this.birthDay = '',
    this.birthMonth = '',
    this.birthYear = '',
    this.salutation = Salutation.unspecified,
    this.email = '',
    this.phone = '',
    this.password = '',
    this.confirmPassword = '',
    this.acceptedTerms = false,
    this.position = '',
    this.specialty = '',
    this.experience,
    this.role,
  });

  final String firstName;
  final String lastName;
  final String birthDay;
  final String birthMonth;
  final String birthYear;
  final Salutation salutation;
  final String email;
  final String phone;
  final String password;
  final String confirmPassword;
  final bool acceptedTerms;
  final String position;
  final String specialty;
  final ExperienceRange? experience;
  final PmoRole? role;

  String get fullName => '${firstName.trim()} ${lastName.trim()}'.trim();

  RegistrationDraft copyWith({
    String? firstName,
    String? lastName,
    String? birthDay,
    String? birthMonth,
    String? birthYear,
    Salutation? salutation,
    String? email,
    String? phone,
    String? password,
    String? confirmPassword,
    bool? acceptedTerms,
    String? position,
    String? specialty,
    ExperienceRange? experience,
    PmoRole? role,
  }) {
    return RegistrationDraft(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDay: birthDay ?? this.birthDay,
      birthMonth: birthMonth ?? this.birthMonth,
      birthYear: birthYear ?? this.birthYear,
      salutation: salutation ?? this.salutation,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      position: position ?? this.position,
      specialty: specialty ?? this.specialty,
      experience: experience ?? this.experience,
      role: role ?? this.role,
    );
  }
}

abstract final class PasswordPolicy {
  static const minLength = 8;

  static PasswordStrength strength(String password) {
    if (password.isEmpty) {
      return PasswordStrength.none;
    }
    var score = 0;
    if (password.length >= minLength) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp('[A-Z]')) && password.contains(RegExp('[a-z]'))) score++;
    if (password.contains(RegExp(r'\d'))) score++;
    if (password.contains(RegExp(r'[^A-Za-z0-9]'))) score++;
    if (password.length < minLength || score <= 2) {
      return PasswordStrength.weak;
    }
    return score <= 3 ? PasswordStrength.medium : PasswordStrength.strong;
  }

  static bool isAcceptable(String password) =>
      password.length >= minLength && strength(password) != PasswordStrength.weak;
}

abstract final class EmailPolicy {
  static final _regex = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

  static bool isValid(String email) => _regex.hasMatch(email.trim());
}

/// Port to the identity provider (mock implementation in `iam/data`).
abstract class AuthRepository {
  Future<User> login(Credentials credentials);

  Future<User> register(RegistrationDraft draft);

  Future<void> requestPasswordReset(String email);

  Future<void> verifyResetCode(String email, String code);

  Future<void> resetPassword(String email, String code, String newPassword);

  Future<void> saveToken(Token token);

  Token? get token;

  Future<void> saveUserProfile(User user);

  User? get currentUser;

  Future<void> saveProfileAvatar(String path);

  Future<void> updateUserEmail(String email);

  Future<void> clearSession();
}
