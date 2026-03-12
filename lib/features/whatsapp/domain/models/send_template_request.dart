class SendTemplateRequest {
  final String to;
  final String templateName;
  final String languageCode;
  final List<Map<String, dynamic>>? components;

  const SendTemplateRequest({
    required this.to,
    required this.templateName,
    required this.languageCode,
    this.components,
  });

  Map<String, dynamic> toJson() => {
      'to': to,
      'template_name': templateName,
      'language_code': languageCode,
      'components': components,
  };
}
