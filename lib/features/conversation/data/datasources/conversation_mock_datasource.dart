// ─────────────────────────────────────────────────────────────
// PATCH: conversation_mock_datasource.dart
// ─────────────────────────────────────────────────────────────
// Add these inside the ConversationMockDataSource class body
// (e.g. after line ~28, after the onTypingStop field):

final Map<String, String> _nameCache = {};

@override
Map<String, String> get nameCache => Map.unmodifiable(_nameCache);

@override
void registerName(String actorId, String name) {
  if (actorId.isNotEmpty && name.isNotEmpty) {
    _nameCache[actorId] = name;
  }
}
