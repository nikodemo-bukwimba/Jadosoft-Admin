// datetime_extensions.dart
// ─────────────────────────────────────────────────────────────
// Extension methods on DateTime and DateTime?.
//
// Every method here has a concrete use site in this template:
//   - savedAt / createdAt on AccountSession / UserEntity
//   - emailVerifiedAt on UserEntity
//   - sessionTimeoutMinutes from AppConstants
//   - "last seen" / "joined" display in ProfilePage
//   - session age check for background re-auth
//
// Import:
//   import 'package:fca/core/extensions/datetime_extensions.dart';
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
// Non-nullable DateTime extensions
// ─────────────────────────────────────────────────────────────

extension DateTimeX on DateTime {
  // ── Relative time ─────────────────────────────────────────

  /// Returns a human-readable "time ago" string.
  /// Used on ProfilePage and session debug panels.
  ///
  /// ```dart
  /// session.savedAt.timeAgo   // → 'just now' / '3 min ago' / '2 days ago'
  /// ```
  String get timeAgo {
    final diff = DateTime.now().difference(this);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} wk ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} mo ago';
    return '${(diff.inDays / 365).floor()} yr ago';
  }

  // ── Formatting ────────────────────────────────────────────

  /// Formats as 'MMM d, yyyy' — e.g. 'Mar 7, 2026'.
  /// Used for createdAt / joined date on ProfilePage.
  String get displayDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[month - 1]} $day, $year';
  }

  /// Formats as 'MMM d, yyyy · HH:mm' — e.g. 'Mar 7, 2026 · 14:30'.
  /// Used for savedAt timestamps in the account switcher debug view.
  String get displayDateTime {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$displayDate · $h:$m';
  }

  /// Formats as 'HH:mm' — e.g. '09:05'.
  String get displayTime {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Formats as ISO 8601 date-only — 'yyyy-MM-dd'. Safe for API params.
  String get isoDate =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  // ── Predicates ────────────────────────────────────────────

  /// True if this DateTime is today (in local time).
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// True if this DateTime was yesterday (in local time).
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// True if this DateTime is in the past.
  bool get isPast => isBefore(DateTime.now());

  /// True if this DateTime is in the future.
  bool get isFuture => isAfter(DateTime.now());

  // ── Session helpers ───────────────────────────────────────

  /// True if the session is older than [minutes].
  ///
  /// Used by AuthBloc to decide whether a background re-auth is needed.
  ///
  /// ```dart
  /// if (session.savedAt.isOlderThan(AppConstants.sessionTimeoutMinutes)) {
  ///   add(AuthSessionRefreshRequested());
  /// }
  /// ```
  bool isOlderThan(int minutes) =>
      DateTime.now().difference(this).inMinutes >= minutes;

  /// True if the session was saved within [minutes] ago.
  bool isFresherThan(int minutes) => !isOlderThan(minutes);

  /// How many minutes have elapsed since this DateTime.
  int get minutesElapsed => DateTime.now().difference(this).inMinutes;

  /// How many seconds have elapsed since this DateTime.
  int get secondsElapsed => DateTime.now().difference(this).inSeconds;

  // ── Arithmetic helpers ────────────────────────────────────

  /// Returns a new DateTime with only the date component (time zeroed).
  DateTime get dateOnly => DateTime(year, month, day);

  /// Returns a copy of this DateTime with the given fields replaced.
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
  }) => DateTime(
    year ?? this.year,
    month ?? this.month,
    day ?? this.day,
    hour ?? this.hour,
    minute ?? this.minute,
    second ?? this.second,
    millisecond ?? this.millisecond,
  );
}

// ─────────────────────────────────────────────────────────────
// Nullable DateTime extensions
// ─────────────────────────────────────────────────────────────

extension NullableDateTimeX on DateTime? {
  /// Returns [fallback] when null, otherwise calls [displayDate].
  ///
  /// ```dart
  /// user.createdAt.displayDateOrDefault('Unknown')
  /// ```
  String displayDateOrDefault([String fallback = '—']) =>
      this == null ? fallback : this!.displayDate;

  /// Returns [fallback] when null, otherwise calls [displayDateTime].
  String displayDateTimeOrDefault([String fallback = '—']) =>
      this == null ? fallback : this!.displayDateTime;

  /// Returns [fallback] when null, otherwise calls [timeAgo].
  ///
  /// ```dart
  /// user.emailVerifiedAt.timeAgoOrDefault('Not verified')
  /// ```
  String timeAgoOrDefault([String fallback = 'Never']) =>
      this == null ? fallback : this!.timeAgo;

  /// True if non-null and in the past — used for email verification check.
  ///
  /// ```dart
  /// final isVerified = user.emailVerifiedAt.isVerified;
  /// ```
  bool get isVerified => this != null && this!.isPast;

  /// True if null — readable inverse of [isVerified].
  bool get isNotVerified => !isVerified;
}

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
