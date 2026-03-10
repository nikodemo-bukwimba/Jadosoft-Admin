// actor_repository_impl.dart
// ─────────────────────────────────────────────────────────────
// API-first with local cache fallback.
//
// Strategy (matches ProfileRepositoryImpl pattern):
//
//   READ (getAll / getById):
//     1. Try remote API
//     2. On success → cache result locally → return fresh data
//     3. On NetworkException → serve stale cache if available
//     4. On ServerException  → serve stale cache if available
//     5. On AuthException    → do NOT serve stale — force re-login
//     6. No cache available  → return the failure
//
//   WRITE (create / update / delete):
//     Always remote. On success → update local cache.
//     Writes never fall back to cache.
//
// TTL is controlled by AppConstants.actorCacheTtlMinutes.
// When cache is fresh AND remote succeeds, remote always wins.
// ─────────────────────────────────────────────────────────────

import 'package:dartz/dartz.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/actor_entity.dart';
import '../../domain/repositories/actor_repository.dart';
import '../models/actor_model.dart';
import '../datasources/actor_remote_datasource.dart';
import '../datasources/actor_local_datasource.dart';

class ActorRepositoryImpl implements ActorRepository {
  final ActorRemoteDataSource _remote;
  final ActorLocalDataSource _local;

  ActorRepositoryImpl({
    required ActorRemoteDataSource remote,
    required ActorLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  // ── GET ALL ──────────────────────────────────────────────

  @override
  Future<Either<Failure, List<ActorEntity>>> getAll() async {
    // ── Step 1: Try remote API ────────────────────────────
    try {
      final actors = await _remote.getAll();

      // ── Step 2: Cache the fresh result ──────────────────
      try {
        await _local.cacheAll(actors);
      } catch (_) {
        // Cache write failure is non-fatal — still return fresh data
      }

      return Right(actors);
    } on AuthException catch (e) {
      // ── Auth error — never serve stale ──────────────────
      return Left(AuthFailure(e.message));
    } on NetworkException catch (_) {
      // ── Network failure — try stale cache ───────────────
      return _fallbackToCache();
    } on ServerException catch (e) {
      // ── Server error — try stale cache ──────────────────
      return _fallbackToCache(serverMessage: e.message);
    } catch (e) {
      return _fallbackToCache(serverMessage: e.toString());
    }
  }

  // ── GET BY ID ────────────────────────────────────────────

  @override
  Future<Either<Failure, ActorEntity>> getById(String id) async {
    try {
      final actor = await _remote.getById(id);

      // Cache the single actor
      try {
        await _local.cacheOne(actor);
      } catch (_) {}

      return Right(actor);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (_) {
      return _fallbackToSingleCache(id);
    } on ServerException catch (e) {
      return _fallbackToSingleCache(id, serverMessage: e.message);
    } catch (e) {
      return _fallbackToSingleCache(id, serverMessage: e.toString());
    }
  }

  // ── CREATE ───────────────────────────────────────────────

  @override
  Future<Either<Failure, ActorEntity>> create(ActorEntity entity) async {
    try {
      final model = ActorModel.fromEntity(entity);
      final result = await _remote.create(model.toCreateJson());

      // Add to local cache
      try {
        await _local.cacheOne(result);
      } catch (_) {}

      return Right(result);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  // ── UPDATE ───────────────────────────────────────────────

  @override
  Future<Either<Failure, ActorEntity>> update(ActorEntity entity) async {
    try {
      final model = ActorModel.fromEntity(entity);
      final result = await _remote.update(entity.id, model.toCreateJson());

      // Update local cache
      try {
        await _local.cacheOne(result);
      } catch (_) {}

      return Right(result);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  // ── DELETE ───────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      await _remote.delete(id);

      // Remove from local cache
      try {
        await _local.deleteById(id);
      } catch (_) {}

      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  // ── Cache fallback helpers ───────────────────────────────

  Future<Either<Failure, List<ActorEntity>>> _fallbackToCache({
    String? serverMessage,
  }) async {
    try {
      final cached = await _local.getAll();
      if (cached.isNotEmpty) {
        return Right(cached);
      }
    } catch (_) {}

    // No cache available — return the original error
    return Left(
      serverMessage != null
          ? ServerFailure(serverMessage)
          : const NetworkFailure('Cannot reach the server.'),
    );
  }

  Future<Either<Failure, ActorEntity>> _fallbackToSingleCache(
    String id, {
    String? serverMessage,
  }) async {
    try {
      final cached = await _local.getById(id);
      if (cached != null) {
        return Right(cached);
      }
    } catch (_) {}

    return Left(
      serverMessage != null
          ? ServerFailure(serverMessage)
          : const NetworkFailure('Cannot reach the server.'),
    );
  }
}