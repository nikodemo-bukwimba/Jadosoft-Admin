// lib/features/conversation/data/datasources/conversation_api_datasource.dart
//
// Production datasource — re-exports ConversationRemoteDataSourceImpl.
// This file exists so DI can import a stable symbol that is always the
// "real API" implementation, independent of the abstract interface file.

export 'conversation_remote_datasource.dart' show ConversationRemoteDataSourceImpl;