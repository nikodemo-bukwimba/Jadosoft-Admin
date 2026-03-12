class SendSmsRequest {
  final String to;
  final String message;
  final String? from;

  const SendSmsRequest({
    required this.to,
    required this.message,
    this.from,
  });

  Map<String, dynamic> toJson() => {
      'to': to,
      'message': message,
      'from': from,
  };
}
