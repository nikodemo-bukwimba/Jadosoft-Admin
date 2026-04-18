import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/visit_entity.dart';
import '../guards/visit_transition_guard.dart';
import '../repositories/visit_repository.dart';
import '../value_objects/visit_status.dart';

class VisitDomainService {
  final VisitRepository repository;
  final VisitTransitionGuard guard;

  VisitDomainService({required this.repository, required this.guard});

  Future<Either<Failure, VisitEntity>> transition({
    required String id,
    required VisitStatus targetStatus,
  }) async {
    final loadResult = await repository.getById(id);
    if (loadResult.isLeft()) return loadResult;
    final entity = loadResult.getOrElse(() => throw StateError('unreachable'));

    final guardResult = guard.validate(
      current: VisitStatusX.fromString(entity.status),
      target: targetStatus,
    );
    if (guardResult.isLeft()) {
      return guardResult.fold(
        (f) => Left(f),
        (_) => throw StateError('unreachable'),
      );
    }
    final validTarget = guardResult.getOrElse(
      () => throw StateError('unreachable'),
    );
    final updated = entity.copyWith(status: validTarget.name);
    return repository.update(updated);
  }

  /// Accept a completed visit with optional comment for the officer.
  Future<Either<Failure, VisitEntity>> reviewWithComment({
    required String id,
    String? comment,
  }) async {
    final loadResult = await repository.getById(id);
    if (loadResult.isLeft()) return loadResult;
    final entity = loadResult.getOrElse(() => throw StateError('unreachable'));

    final guardResult = guard.validate(
      current: VisitStatusX.fromString(entity.status),
      target: VisitStatus.reviewed,
    );
    if (guardResult.isLeft()) {
      return guardResult.fold(
        (f) => Left(f),
        (_) => throw StateError('unreachable'),
      );
    }

    final comments = List<VisitAdminComment>.from(entity.adminComments);
    if (comment != null && comment.trim().isNotEmpty) {
      comments.add(
        VisitAdminComment(
          id: 'cmt_${DateTime.now().millisecondsSinceEpoch}',
          authorName: 'Admin',
          comment: comment.trim(),
          createdAt: DateTime.now(),
        ),
      );
    }

    final updated = entity.copyWith(
      status: VisitStatus.reviewed.name,
      adminComments: comments,
    );
    // Pass adminComment so the datasource can send it to the review endpoint
    return repository.updateWithAction(
      updated,
      adminComment: comment?.trim().isNotEmpty == true ? comment!.trim() : null,
    );
  }

  /// Flag a visit with a required comment explaining the reason.
  Future<Either<Failure, VisitEntity>> flagWithComment({
    required String id,
    required String comment,
  }) async {
    if (comment.trim().isEmpty) {
      return const Left(
        ValidationFailure('A comment is required when flagging a visit.'),
      );
    }

    final loadResult = await repository.getById(id);
    if (loadResult.isLeft()) return loadResult;
    final entity = loadResult.getOrElse(() => throw StateError('unreachable'));

    final current = VisitStatusX.fromString(entity.status);
    if (current != VisitStatus.pending && current != VisitStatus.reviewed) {
      return Left(
        ValidationFailure(
          'Cannot flag from ${current.displayName}. Only pending or reviewed visits can be flagged.',
        ),
      );
    }

    final comments = List<VisitAdminComment>.from(entity.adminComments);
    comments.add(
      VisitAdminComment(
        id: 'cmt_${DateTime.now().millisecondsSinceEpoch}',
        authorName: 'Admin',
        comment: comment.trim(),
        createdAt: DateTime.now(),
      ),
    );

    final updated = entity.copyWith(
      status: VisitStatus.flagged.name,
      flagReason: comment.trim(),
      adminComments: comments,
    );
    return repository.updateWithAction(updated, flagReason: comment.trim());
  }

  /// Unflag a visit — move back to reviewed.
  Future<Either<Failure, VisitEntity>> unflagVisit({required String id}) async {
    return transition(id: id, targetStatus: VisitStatus.reviewed);
  }
}
