// profile_event.dart
abstract class ProfileEvent {}

/// Load/refresh the current user's profile from the API.
class ProfileLoadRequested extends ProfileEvent {}
