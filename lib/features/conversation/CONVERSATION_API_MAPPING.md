# Conversations Feature — Complete API Mapping & Gap Analysis

## For: Laravel API Development Team + Flutter Development Team
## Feature: Seq 14 — Conversations (L1) — In-app Messaging & Communication
## Date: 2026-03-24

---

## Architecture Context

The admin app has a **full-featured chat system** (6733 lines, Maishell-generated) with:
- Direct messages (1-to-1)
- Group conversations
- Broadcast messaging
- Reply threads, reactions, pins, stars, edit, delete
- Typing indicators, read receipts, online presence
- Message forwarding, voice notes, image messages
- In-chat search, participant management

The Nexora platform has a **rich Communications module** (API sections 17–21).
This document maps every client feature to a Nexora API endpoint.

---

## COMPLETE FEATURE → API MAPPING

### ✅ ENDPOINTS THAT EXIST (ready to wire)

| # | Feature | Nexora Endpoint | Method | Notes |
|---|---------|-----------------|--------|-------|
| 1 | List DM conversations | `/communications/conversations` | GET | Paginated, ordered by last_message_at |
| 2 | Start/get DM | `/communications/conversations` | POST | Body: `{recipient_actor_id}`. Idempotent — returns existing if pair exists |
| 3 | Get DM messages | `/communications/conversations/{id}/messages` | GET | Paginated newest-first. Includes attachments, reactions, replyTo |
| 4 | Send DM message | `/communications/conversations/{id}/messages` | POST | Supports: content, content_type (text/image/document/audio/location/forwarded), reply_to_id, forwarded_from_id |
| 5 | Mark DM as read | `/communications/conversations/{id}/read` | POST | Marks ALL messages in conversation as read |
| 6 | React to DM | `/communications/messages/dm/{id}/react` | POST | Body: `{emoji}`. Adds or updates reaction |
| 7 | Delete DM for me | `/communications/messages/dm/{id}/me` | DELETE | Soft delete for sender or recipient |
| 8 | Delete DM for everyone | `/communications/messages/dm/{id}/everyone` | DELETE | Nulls content. Sender only |
| 9 | Create group | `/communications/groups` | POST | Body: name, description, type (group/channel), participant_ids, only_admins_can_message |
| 10 | Get group | `/communications/groups/{id}` | GET | Returns group with participants loaded |
| 11 | Get group messages | `/communications/groups/{id}/messages` | GET | Paginated. Includes attachments, reactions, receipts, replyTo |
| 12 | Send group message | `/communications/groups/{id}/messages` | POST | Same fields as DM. Respects only_admins_can_message flag |
| 13 | Mark group as read | `/communications/groups/{id}/read` | POST | Creates/updates message_receipts |
| 14 | Add group participant | `/communications/groups/{id}/participants` | POST | Body: `{actor_id}`. Admin only |
| 15 | Remove group participant | `/communications/groups/{id}/participants/{actorId}` | DELETE | Members remove self; admins remove others |
| 16 | Promote to admin | `/communications/groups/{id}/participants/{actorId}/promote` | POST | Admin only |
| 17 | React to group message | `/communications/messages/group/{messageId}/react` | POST | Body: `{emoji}` |
| 18 | Delete group msg for all | `/communications/messages/group/{messageId}/everyone` | DELETE | Sender or admins only |
| 19 | List broadcast lists | `/communications/broadcasts` | GET | Lists owned by authenticated actor |
| 20 | Create broadcast list | `/communications/broadcasts` | POST | Body: name, org_id, recipient_actor_ids |
| 21 | Send broadcast message | `/communications/broadcasts/{id}/messages` | POST | Same fields as DM. Delivered as individual DM-like messages |
| 22 | List broadcast messages | `/communications/broadcasts/{id}/messages` | GET | History of sent broadcasts |
| 23 | Add broadcast recipient | `/communications/broadcasts/{id}/recipients` | POST | Body: `{actor_id}` |
| 24 | Remove broadcast recipient | `/communications/broadcasts/{id}/recipients/{actorId}` | DELETE | |
| 25 | Bulk presence check | `/communications/presence/bulk` | POST | Body: `{actor_ids: [...]}`. Max 100. Returns is_online, last_seen_at |
| 26 | Create DM from group (private reply) | `/communications/conversations` | POST | Just creates a DM with `{recipient_actor_id}` — same as #2 |

---

### 🔴 ENDPOINTS THAT ARE MISSING (need Laravel implementation)

| # | Feature | Proposed Endpoint | Method | Priority | Why Needed |
|---|---------|-------------------|--------|----------|------------|
| M1 | **Pin message** | `/communications/messages/{scope}/{id}/pin` | POST | **HIGH** | Admin pins important messages (instructions, announcements) so they stay visible at top of chat. Officers/customers see pinned messages immediately when opening conversation. Without this, critical information gets buried in chat history. |
| M2 | **Unpin message** | `/communications/messages/{scope}/{id}/unpin` | POST | **HIGH** | Pairs with pin. Admin removes outdated pinned messages. |
| M3 | **Get pinned messages** | `/communications/conversations/{id}/pinned` OR `/communications/groups/{id}/pinned` | GET | **HIGH** | Side panel shows all pinned messages for quick reference. Used in the chat side panel (already built in UI). |
| M4 | **Star message** | `/communications/messages/{scope}/{id}/star` | POST | **MEDIUM** | Personal bookmarking. Admin stars messages to follow up on later. Stars are per-user — other participants don't see them. |
| M5 | **Unstar message** | `/communications/messages/{scope}/{id}/unstar` | POST | **MEDIUM** | Remove personal bookmark. |
| M6 | **Get starred messages** | `/communications/starred` | GET | **MEDIUM** | Cross-conversation view of all starred messages for the authenticated user. |
| M7 | **Edit message** | `/communications/messages/{scope}/{id}` | PATCH | **HIGH** | Admin corrects typos or updates instructions. Sets `is_edited=true`, `edited_at` timestamp. Original content preserved in audit log. Important for accountability — admin can't silently change what they said. |
| M8 | **Search messages** | `/communications/conversations/{id}/search?q=` OR `/communications/groups/{id}/search?q=` | GET | **MEDIUM** | Server-side full-text search within a conversation. Currently client-side only (works on loaded messages). Server search needed when message history exceeds loaded page size. |
| M9 | **Per-message read receipts** | `/communications/messages/{scope}/{id}/receipts` | GET | **LOW** | Shows exactly who read a specific message and when. Nexora has mark-all-read (`POST .../read`) but no per-message receipt query. The database schema has `message_receipts` table — just needs an API endpoint to query it. |
| M10 | **Close conversation** | `/communications/conversations/{id}/close` OR `/communications/groups/{id}/close` | POST | **MEDIUM** | Admin closes resolved conversations. Prevents further messages until reopened. Sets `status=closed`, `closed_by`, `closed_at`. Used for accountability — conversation is preserved but archived. |
| M11 | **Reopen conversation** | `/communications/conversations/{id}/reopen` OR `/communications/groups/{id}/reopen` | POST | **MEDIUM** | Admin reopens a closed conversation when follow-up is needed. Sets `status=open`, clears closed_by/closed_at. |
| M12 | **Typing indicator** | WebSocket/Pusher channel | — | **LOW** | Real-time "X is typing..." display. Not a REST endpoint — requires WebSocket (Laravel Echo + Pusher/Soketi). Currently simulated in mock. Can be deferred to Phase 2. |
| M13 | **Update conversation** | `/communications/conversations/{id}` OR `/communications/groups/{id}` | PATCH | **LOW** | Update group title/description. Not critical for admin monitoring. Groups already have PATCH via the group management endpoints. |
| M14 | **Delete conversation** | `/communications/conversations/{id}` | DELETE | **LOW** | Admin archives a conversation permanently. Low priority — closing is sufficient for most use cases. |
| M15 | **Mentions** | No endpoint needed | — | **N/A** | Mentions (@user, @all) are stored as metadata in the message content field. Parsed client-side. No separate API needed — just ensure `mentioned_user_ids` array is included in the message POST body. |

---

### DETAILED ENDPOINT SPECIFICATIONS FOR MISSING ITEMS

#### M1 — Pin Message

**Why:** Admin pins announcements, policy updates, or important instructions at the top of the chat. Officers see pinned messages immediately upon opening the conversation — no scrolling through history.

```
POST /api/v1/communications/messages/{scope}/{messageId}/pin
```

Where `{scope}` is `dm` or `group`.

**Constraint:** Only admins/group-admins can pin. Max 25 pinned messages per conversation.

**Database:** Add `pinned_at TIMESTAMP NULL` and `pinned_by ULID NULL` to `messages` table.

**Response:**
```json
{
  "message": "Message pinned.",
  "pinned_at": "2026-03-24T10:00:00.000000Z",
  "pinned_by": "01KK..."
}
```

#### M3 — Get Pinned Messages

```
GET /api/v1/communications/conversations/{id}/pinned
GET /api/v1/communications/groups/{id}/pinned
```

**Response:** Array of message objects where `pinned_at IS NOT NULL`, ordered by `pinned_at DESC`.

#### M4 — Star Message

**Why:** Personal bookmarking for follow-up. Admin stars a customer complaint to address later. Stars are private — only the starring user sees them.

```
POST /api/v1/communications/messages/{scope}/{messageId}/star
```

**Database:** New table `message_stars (message_id ULID, actor_id ULID, starred_at TIMESTAMP, PRIMARY KEY (message_id, actor_id))`.

#### M6 — Get Starred Messages (cross-conversation)

```
GET /api/v1/communications/starred
```

**Response:** Paginated list of starred messages across all conversations for the authenticated user. Each includes the conversation context (id, title/participant names).

#### M7 — Edit Message

**Why:** Admin corrects typos in instructions sent to officers. The edit trail is preserved — `is_edited=true` and `edited_at` timestamp visible to all participants.

```
PATCH /api/v1/communications/messages/{scope}/{messageId}
```

**Body:** `{ "content": "corrected encrypted content" }`

**Constraint:** Only sender can edit. Editing allowed within 24 hours of sending.

**Database:** Add `is_edited BOOLEAN DEFAULT FALSE`, `edited_at TIMESTAMP NULL`, `original_content TEXT NULL` to messages.

**Response:**
```json
{
  "message": "Message updated.",
  "is_edited": true,
  "edited_at": "2026-03-24T10:05:00.000000Z"
}
```

#### M8 — Search Messages

**Why:** Admin searches for specific customer names, product references, or keywords in long conversation histories. Client-side search only works for loaded messages — server search covers the full history.

```
GET /api/v1/communications/conversations/{id}/search?q=amoxicillin
GET /api/v1/communications/groups/{id}/search?q=amoxicillin
```

**Response:** Paginated messages matching the query, newest first.

**Implementation:** PostgreSQL `ts_vector` full-text search on decrypted content. Note: if content is encrypted (E2E), server search is impossible — client-side search is the only option.

#### M9 — Per-Message Read Receipts

**Why:** In group conversations, admin needs to know which officers read a critical instruction. "5 of 8 read" indicator on the message.

```
GET /api/v1/communications/messages/{scope}/{messageId}/receipts
```

**Response:**
```json
{
  "total_participants": 8,
  "read_count": 5,
  "receipts": [
    { "actor_id": "01KK...", "name": "John Mwangi", "read_at": "2026-03-24T10:01:00Z" },
    { "actor_id": "01KK...", "name": "Sarah Kimaro", "read_at": "2026-03-24T10:03:00Z" }
  ]
}
```

**Database:** Already exists as `message_receipts` table in HMSCP schema.

#### M10 + M11 — Close/Reopen Conversation

**Why:** Admin closes resolved support conversations to keep the inbox clean. Closed conversations are visible but greyed out. Reopening restores full messaging.

```
POST /api/v1/communications/conversations/{id}/close
POST /api/v1/communications/conversations/{id}/reopen
POST /api/v1/communications/groups/{id}/close
POST /api/v1/communications/groups/{id}/reopen
```

**Close response:**
```json
{
  "message": "Conversation closed.",
  "status": "closed",
  "closed_by": "01KK...",
  "closed_at": "2026-03-24T16:00:00.000000Z"
}
```

**Database:** `conversations` table already has `status` column. Need `closed_by ULID NULL` and `closed_at TIMESTAMP NULL` columns.

---

## PRIORITY SUMMARY

| Priority | Endpoints | Impact |
|----------|-----------|--------|
| **HIGH** | M1 (pin), M2 (unpin), M3 (get pinned), M7 (edit) | Core admin workflow — pinning instructions and correcting messages |
| **MEDIUM** | M4-M6 (stars), M8 (search), M10-M11 (close/reopen) | Productivity and inbox management |
| **LOW** | M9 (receipts), M12 (typing), M13 (update conv), M14 (delete conv) | Nice-to-have, can defer |

---

## BLoC ARCHITECTURE NOTE (for Flutter team)

The current BLoC hardcodes `ConversationMockDataSource()` directly:
```dart
final ConversationMockDataSource _mockDs = ConversationMockDataSource();
```

For production, this needs to be **injected via constructor** so the DI container can swap mock for real:
```dart
// In BLoC constructor — add this parameter:
final ConversationRemoteDataSource messageDataSource;

// In DI:
sl.registerFactory<ConversationBloc>(() => ConversationBloc(
  getAllUseCase: sl(), getUseCase: sl(), createUseCase: sl(),
  updateUseCase: sl(), deleteUseCase: sl(),
  messageDataSource: sl<ConversationRemoteDataSource>(),
));
```

This is the ONLY structural change needed. All events, states, pages, and widgets remain unchanged.

---

## NEXORA API → DATASOURCE METHOD MAPPING

| Mock Method | Nexora API | Scope |
|-------------|-----------|-------|
| `getAll()` | `GET /communications/conversations` | DM list |
| `getById(id)` | `GET /communications/groups/{id}` or context | Both |
| `create(data)` | `POST /communications/conversations` (DM) or `POST /communications/groups` (group) | Both |
| `getMessages(convId)` | `GET /communications/conversations/{id}/messages` or `/groups/{id}/messages` | Both |
| `sendMessage(...)` | `POST /communications/conversations/{id}/messages` or `/groups/{id}/messages` | Both |
| `deleteMessage(convId, msgId)` | `DELETE /communications/messages/dm/{id}/everyone` or `/group/{id}/everyone` | Both |
| `addReaction(convId, msgId, emoji)` | `POST /communications/messages/dm/{id}/react` or `/group/{id}/react` | Both |
| `addParticipant(convId, pId, ...)` | `POST /communications/groups/{id}/participants` | Group only |
| `removeParticipant(convId, pId, ...)` | `DELETE /communications/groups/{id}/participants/{actorId}` | Group only |
| `broadcastMessage(convIds, content)` | `POST /communications/broadcasts/{id}/messages` | Broadcast |
| `createPrivateFromGroup(pId, ...)` | `POST /communications/conversations` with `{recipient_actor_id}` | DM |
| `togglePin(convId, msgId)` | 🔴 `POST /messages/{scope}/{id}/pin` or `/unpin` | MISSING |
| `toggleStar(convId, msgId)` | 🔴 `POST /messages/{scope}/{id}/star` or `/unstar` | MISSING |
| `editMessage(convId, msgId, content)` | 🔴 `PATCH /messages/{scope}/{id}` | MISSING |
| `getReadReceipts(convId, msgId)` | 🔴 `GET /messages/{scope}/{id}/receipts` | MISSING |
| `searchMessages(convId, query)` | 🔴 Client-side (or `GET .../search?q=`) | MISSING (server) |
| `getPinnedMessages(convId)` | 🔴 `GET .../pinned` | MISSING |
| `closeConversation(convId)` | 🔴 `POST .../close` | MISSING |
| `reopenConversation(convId)` | 🔴 `POST .../reopen` | MISSING |
| Online presence | `POST /communications/presence/bulk` | ✅ EXISTS |
| Mark as read | `POST /communications/conversations/{id}/read` or `/groups/{id}/read` | ✅ EXISTS |
