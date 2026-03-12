class InitiatePaymentRequest {
  final double amount;
  final String currency;
  final String phoneNumber;
  final String provider;
  final String reference;
  final String? description;

  const InitiatePaymentRequest({
    required this.amount,
    required this.currency,
    required this.phoneNumber,
    required this.provider,
    required this.reference,
    this.description,
  });

  Map<String, dynamic> toJson() => {
      'amount': amount,
      'currency': currency,
      'phone_number': phoneNumber,
      'provider': provider,
      'reference': reference,
      'description': description,
  };
}
