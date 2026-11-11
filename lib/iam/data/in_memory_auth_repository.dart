import 'package:flutter/foundation.dart';
import 'package:mdeps_flutter/iam/domain/iam_models.dart';

/// Mock identity provider kept in memory (mirrors `DataStoreAuthRepository`).
class InMemoryAuthRepository extends ChangeNotifier implements AuthRepository {
  static const resetCodeLength = 6;
  static const _networkDelay = Duration(milliseconds: 800);
  static const _roleProjectLeader = 'Project Leader';
  static const _roleEnterpriseOwner = 'Enterprise Owner';

  static const mockUser = User(
    id: 'usr-ent-88492',
    email: 'alex.vance@enterprise.com',
    name: 'Alejandro Vance Rivas',
    role: 'Senior Delivery & PMO Director',
  );

  Token? _token;
  User? _user;

  @override
  Token? get token => _token;

  @override
  User? get currentUser => _user;

  @override
  Future<User> login(Credentials credentials) async {
    await Future<void>.delayed(_networkDelay);
    if (credentials.email.trim().isEmpty || credentials.password.isEmpty) {
      throw ArgumentError('Email and password are required.');
    }
    final email = credentials.email.trim();
    final stored = _user;
    if (stored != null && stored.email.toLowerCase() == email.toLowerCase()) {
      return stored;
    }
    return mockUser.copyWith(email: email);
  }

  @override
  Future<User> register(RegistrationDraft draft) async {
    await Future<void>.delayed(_networkDelay * 2);
    if (draft.fullName.isEmpty || !EmailPolicy.isValid(draft.email)) {
      throw ArgumentError('Incomplete registration data.');
    }
    if (!PasswordPolicy.isAcceptable(draft.password)) {
      throw ArgumentError('Password does not meet the policy.');
    }
    return User(
      id: 'usr-ent-${draft.email.trim().toLowerCase().hashCode.abs()}',
      email: draft.email.trim(),
      name: draft.fullName,
      role: draft.role == PmoRole.enterpriseOwner ? _roleEnterpriseOwner : _roleProjectLeader,
    );
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await Future<void>.delayed(_networkDelay);
    if (!EmailPolicy.isValid(email)) {
      throw ArgumentError('Invalid email.');
    }
  }

  @override
  Future<void> verifyResetCode(String email, String code) async {
    await Future<void>.delayed(_networkDelay);
    // Mock: any 6-digit numeric code is valid.
    if (code.length != resetCodeLength || !RegExp(r'^\d+$').hasMatch(code)) {
      throw ArgumentError('Invalid code.');
    }
  }

  @override
  Future<void> resetPassword(String email, String code, String newPassword) async {
    await Future<void>.delayed(_networkDelay);
    if (!PasswordPolicy.isAcceptable(newPassword)) {
      throw ArgumentError('Password does not meet the policy.');
    }
  }

  @override
  Future<void> saveToken(Token token) async {
    _token = token;
  }

  @override
  Future<void> saveUserProfile(User user) async {
    final avatar = user.avatarPath ?? _user?.avatarPath;
    _user = user.copyWith(avatarPath: avatar);
    notifyListeners();
  }

  @override
  Future<void> saveProfileAvatar(String path) async {
    final user = _user;
    if (user != null) {
      _user = user.copyWith(avatarPath: path);
      notifyListeners();
    }
  }

  @override
  Future<void> updateUserEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Email is required.');
    }
    final user = _user;
    if (user != null) {
      _user = user.copyWith(email: trimmed);
      notifyListeners();
    }
  }

  @override
  Future<void> clearSession() async {
    _token = null;
  }
}
