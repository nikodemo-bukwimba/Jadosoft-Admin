import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/conversation_entity.dart';

abstract class ConversationRepository {
  Future<Either<Failure, List<ConversationEntity>>> getAll();
  Future<Either<Failure, ConversationEntity>>       getById(String id);
  Future<Either<Failure, ConversationEntity>>       create(ConversationEntity entity);
  Future<Either<Failure, ConversationEntity>>       update(ConversationEntity entity);
  Future<Either<Failure, void>>                 delete(String id);
}
