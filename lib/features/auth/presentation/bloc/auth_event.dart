// auth_event.dart
// ─────────────────────────────────────────────────────────────
// All events the UI can send to AuthBloc.
// UI never calls use cases or repositories directly.
// ─────────────────────────────────────────────────────────────

abstract class AuthEvent {}

/// App startup — check for an existing active session.
class AuthCheckRequested extends AuthEvent {}

/// User submitted the login form.
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  AuthLoginRequested({required this.email, required this.password});
}

/// User submitted the registration form.
class AuthRegisterRequested extends AuthEvent {
  final String  name;
  final String  email;
  final String  password;
  final String  passwordConfirmation;
  final String? phone;
  AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    this.phone,
  });
}

/// User pressed "Logout" for the active account.
class AuthLogoutRequested extends AuthEvent {}

/// User pressed "Remove account" for a specific saved account.
class AuthLogoutAccountRequested extends AuthEvent {
  final String email;
  AuthLogoutAccountRequested(this.email);
}

/// User tapped a saved account to switch to it.
class AuthSwitchAccountRequested extends AuthEvent {
  final String email;
  AuthSwitchAccountRequested(this.email);
}

/// Reload the saved accounts list (e.g. after adding a new one).
class AuthAccountsRefreshRequested extends AuthEvent {}

/// Refresh the active session data from the API.
class AuthSessionRefreshRequested extends AuthEvent {}
