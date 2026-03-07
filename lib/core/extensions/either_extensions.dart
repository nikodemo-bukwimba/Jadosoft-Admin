// either_extensions.dart
// ─────────────────────────────────────────────────────────────
// Extension methods on Either<Failure, T> from the dartz package.
//
// Design: every method here has a concrete use site in the template.
// Nothing is added speculatively.
//
// Import:
//   import 'package:fca/core/extensions/either_extensions.dart';
//
// Quick reference:
//   result.isRight           → bool
//   result.isLeft            → bool
//   result.rightOrNull       → T?
//   result.leftOrNull        → Failure?
//   result.getOrElse(orElse) → T
//   result.getOrThrow()      → T  (throws if Left)
//   result.mapRight(fn)      → Either<Failure, R>
//   result.onSuccess(fn)     → Either<Failure, T>  (side-effect)
//   result.onFailure(fn)     → Either<Failure, T>  (side-effect)
//   result.toNullable()      → T?
//   result.errorMessage      → String?  (Failure.message or null)
//
// Async helpers (on Future<Either<Failure, T>>):
//   future.foldAsync(onLeft, onRight)
//   future.onSuccessAsync(fn)
//   future.onFailureAsync(fn)
// ─────────────────────────────────────────────────────────────

import 'package:dartz/dartz.dart';

import '../error/failures.dart';

// ─────────────────────────────────────────────────────────────
// Synchronous extensions
// ─────────────────────────────────────────────────────────────

extension EitherX<L extends Failure, R> on Either<L, R> {
  // ── Predicates ────────────────────────────────────────────

  /// True if this is a [Right] (success).
  bool get isRight => fold((_) => false, (_) => true);

  /// True if this is a [Left] (failure).
  bool get isLeft => !isRight;

  // ── Unwrapping ────────────────────────────────────────────

  /// Returns the [Right] value or null.
  ///
  /// ```dart
  /// final session = result.rightOrNull;
  /// if (session != null) { /* use it */ }
  /// ```
  R? get rightOrNull => fold((_) => null, (r) => r);

  /// Returns the [Left] failure or null.
  ///
  /// ```dart
  /// final failure = result.leftOrNull;
  /// if (failure != null) showSnackBar(failure.message);
  /// ```
  L? get leftOrNull => fold((l) => l, (_) => null);

  /// Returns the [Failure.message] from a [Left], or null.
  ///
  /// Shorthand for the common UI pattern:
  /// ```dart
  /// if (state is AuthFailureState)
  ///   Text(result.errorMessage ?? 'Unknown error')
  /// ```
  String? get errorMessage => leftOrNull?.message;

  /// Returns the [Right] value, falling back to [orElse] on failure.
  ///
  /// ```dart
  /// final accounts = result.getOrElse([]);
  /// ```
  R getOrElse(R orElse) => fold((_) => orElse, (r) => r);

  /// Returns the [Right] value or throws a [StateError] with the
  /// [Failure.message].
  ///
  /// Only use in tests or situations where Left is genuinely impossible.
  R getOrThrow() =>
      fold((l) => throw StateError('Either was Left: ${l.message}'), (r) => r);

  /// Converts to a nullable [Right] value — identical to [rightOrNull]
  /// but reads more naturally in widget code:
  ///
  /// ```dart
  /// final name = result.toNullable()?.user.displayName ?? '';
  /// ```
  R? toNullable() => rightOrNull;

  // ── Transformations ───────────────────────────────────────

  /// Maps the [Right] value while preserving [Left] unchanged.
  ///
  /// ```dart
  /// final names = result.mapRight((session) => session.user.displayName);
  /// ```
  Either<L, T> mapRight<T>(T Function(R value) fn) =>
      fold((l) => Left(l), (r) => Right(fn(r)));

  /// Maps the [Left] failure while preserving [Right] unchanged.
  ///
  /// Useful to re-type or enrich a failure before passing it up.
  Either<F, R> mapLeft<F extends Failure>(F Function(L failure) fn) =>
      fold((l) => Left(fn(l)), (r) => Right(r));

  // ── Side-effects ──────────────────────────────────────────

  /// Runs [fn] with the [Right] value and returns [this] unchanged.
  /// Does nothing on [Left]. Use for logging, analytics, or BLoC events.
  ///
  /// ```dart
  /// result
  ///   .onSuccess((session) => analytics.logLogin(session.user.email))
  ///   .onFailure((f) => logger.error(f.message));
  /// ```
  Either<L, R> onSuccess(void Function(R value) fn) {
    fold((_) {}, fn);
    return this;
  }

  /// Runs [fn] with the [Left] failure and returns [this] unchanged.
  /// Does nothing on [Right].
  Either<L, R> onFailure(void Function(L failure) fn) {
    fold(fn, (_) {});
    return this;
  }
}

// ─────────────────────────────────────────────────────────────
// Async extensions  (on Future<Either<Failure, R>>)
// ─────────────────────────────────────────────────────────────

extension FutureEitherX<L extends Failure, R> on Future<Either<L, R>> {
  /// Awaits and folds in one expression — removes the boilerplate of
  /// `final result = await useCase(params); result.fold(...)`.
  ///
  /// ```dart
  /// await _loginUseCase(params).foldAsync(
  ///   (failure) => emit(AuthFailureState(failure.message)),
  ///   (session) => emit(AuthAuthenticated(activeSession: session, ...)),
  /// );
  /// ```
  Future<void> foldAsync(
    void Function(L failure) onLeft,
    void Function(R value) onRight,
  ) async {
    (await this).fold(onLeft, onRight);
  }

  /// Awaits and runs [fn] only on [Right]. Returns the resolved Either.
  Future<Either<L, R>> onSuccessAsync(Future<void> Function(R value) fn) async {
    final result = await this;
    result.fold((_) {}, (value) async => await fn(value));
    return result;
  }

  /// Awaits and runs [fn] only on [Left]. Returns the resolved Either.
  Future<Either<L, R>> onFailureAsync(
    Future<void> Function(L failure) fn,
  ) async {
    final result = await this;
    final failure = result.leftOrNull;
    if (failure != null) await fn(failure);
    return result;
  }

  /// Awaits and maps the [Right] value.
  Future<Either<L, T>> mapRightAsync<T>(T Function(R value) fn) async =>
      (await this).mapRight(fn);

  /// Awaits and returns [Right] value or [orElse] on failure.
  Future<R> getOrElseAsync(R orElse) async =>
      (await this).getOrElse(() => orElse);
}
