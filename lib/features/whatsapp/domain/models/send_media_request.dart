class SendMediaRequest {
  final String to;
  final String mediaType;
  final String mediaUrl;
  final String? caption;

  const SendMediaRequest({
    required this.to,
    required this.mediaType,
    required this.mediaUrl,
    this.caption,
  });

  Map<String, dynamic> toJson() => {
      'to': to,
      'media_type': mediaType,
      'media_url': mediaUrl,
      'caption': caption,
  };
}
