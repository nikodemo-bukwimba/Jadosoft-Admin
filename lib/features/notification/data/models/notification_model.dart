// notification_model.dart
// ─────────────────────────────────────────────────────────────
// The backend NotificationController exposes ProductUpdateDelivery
// records mapped as notification DTOs.
//
// Actual backend JSON keys (from SendProductUpdateToCustomer job):
//   id, status, channel, sent_at, failure_reason, retry_count,
//   external_message_id, created_at
//   + nested: customer { id, name, phone }
//             product_update { id, title }
//
// The model handles both the real backend shape and the legacy
// flat shape (recipient_id, recipient_type, content) so existing
// code that creates NotificationEntity objects in-memory still works.
// ─────────────────────────────────────────────────────────────

import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  /// Extra fields returned by backend that the entity does not carry
  final String? externalMessageId;
  final int retryCount;
  final String? customerPhone;
  final String? productUpdateTitle;

  const NotificationModel({
    required super.id,
    required super.recipientId, // maps to customer.id or recipient_id
    required super.recipientType, // always 'customer' from backend
    required super.channel,
    required super.content, // maps to message_text or content
    super.templateId,
    required super.status,
    super.sentAt,
    super.deliveredAt,
    super.failureReason,
    required super.createdAt,
    this.externalMessageId,
    this.retryCount = 0,
    this.customerPhone,
    this.productUpdateTitle,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // ── Resolve recipient fields ──────────────────────────────
    // Backend shape: customer is nested { id, name, phone }
    final customer = json['customer'] as Map<String, dynamic>?;
    final recipientId =
        customer?['id'] as String? ??
        json['recipient_id'] as String? ??
        json['customer_id'] as String? ??
        '';

    final recipientType = json['recipient_type'] as String? ?? 'customer';

    // ── Resolve content / message text ────────────────────────
    // Backend sends 'message_text' from the queued job;
    // legacy or admin-created records may use 'content'.
    final content =
        json['message_text'] as String? ??
        json['content'] as String? ??
        json['msg_text'] as String? ??
        '';

    // ── Resolve status ────────────────────────────────────────
    // Backend status values: pending | sending | sent | failed
    // Frontend maps: pending/sending → queued, sent → sent, failed → failed
    final rawStatus = json['status'] as String? ?? 'queued';
    final status = _normalizeStatus(rawStatus);

    // ── Resolve timestamps ────────────────────────────────────
    DateTime? sentAt;
    if (json['sent_at'] != null) {
      sentAt = DateTime.tryParse(json['sent_at'] as String);
    }

    DateTime? deliveredAt;
    if (json['delivered_at'] != null) {
      deliveredAt = DateTime.tryParse(json['delivered_at'] as String);
    }

    final createdAt = json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
        : DateTime.now();

    // ── Nested extras ─────────────────────────────────────────
    final productUpdate = json['product_update'] as Map<String, dynamic>?;

    return NotificationModel(
      id: json['id'] as String? ?? '',
      recipientId: recipientId,
      recipientType: recipientType,
      channel: json['channel'] as String? ?? 'sms',
      content: content,
      templateId: json['template_id'] as String?,
      status: status,
      sentAt: sentAt,
      deliveredAt: deliveredAt,
      failureReason: json['failure_reason'] as String?,
      createdAt: createdAt,
      externalMessageId: json['external_message_id'] as String?,
      retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
      customerPhone: customer?['phone'] as String? ?? json['phone'] as String?,
      productUpdateTitle:
          productUpdate?['title'] as String? ??
          json['product_update_title'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'recipient_id': recipientId,
    'recipient_type': recipientType,
    'channel': channel,
    'content': content,
    'template_id': templateId,
    'status': status,
    'sent_at': sentAt?.toIso8601String(),
    'delivered_at': deliveredAt?.toIso8601String(),
    'failure_reason': failureReason,
    'created_at': createdAt.toIso8601String(),
    'external_message_id': externalMessageId,
    'retry_count': retryCount,
  };

  static NotificationModel fromEntity(NotificationEntity e) =>
      NotificationModel(
        id: e.id,
        recipientId: e.recipientId,
        recipientType: e.recipientType,
        channel: e.channel,
        content: e.content,
        templateId: e.templateId,
        status: e.status,
        sentAt: e.sentAt,
        deliveredAt: e.deliveredAt,
        failureReason: e.failureReason,
        createdAt: e.createdAt,
      );

  /// Normalise backend status values to frontend enum names.
  static String _normalizeStatus(String raw) => switch (raw.toLowerCase()) {
    'pending' || 'sending' => 'queued',
    'sent' => 'sent',
    'failed' => 'failed',
    'delivered' => 'delivered',
    _ => 'queued',
  };
}
