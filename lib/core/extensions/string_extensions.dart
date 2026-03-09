
extension StringX on String {
  /// Extracts 1–2 letter initials from a display name.
  ///
  /// ```dart
  /// 'John Doe'.initials       // → 'JD'
  /// 'Alice'.initials          // → 'A'
  /// ''.initials               // → '?'
  /// 'Jean-Pierre Dupont'.initials // → 'JD'
  /// ```
  ///
  /// Previously duplicated as a private `_initials()` method in
  /// HomeTab, _AccountAvatarButton, and _RailFooter.
  String get initials {
    final parts = trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return isNotEmpty ? this[0].toUpperCase() : '?';
  }
}
