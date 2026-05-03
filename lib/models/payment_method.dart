class PaymentMethod {
  PaymentMethod({
    required this.id,
    required this.userId,
    required this.cardHolderName,
    required this.last4Digits,
    required this.expiryDate,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String cardHolderName;
  final String last4Digits;
  final String expiryDate;
  final DateTime createdAt;

  PaymentMethod copyWith({
    String? id,
    String? userId,
    String? cardHolderName,
    String? last4Digits,
    String? expiryDate,
    DateTime? createdAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      last4Digits: last4Digits ?? this.last4Digits,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'cardHolderName': cardHolderName,
        'last4Digits': last4Digits,
        'expiryDate': expiryDate,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PaymentMethod.fromJson(Map<String, dynamic> j) => PaymentMethod(
        id: j['id'] as String,
        userId: j['userId'] as String,
        cardHolderName: j['cardHolderName'] as String,
        last4Digits: j['last4Digits'] as String,
        expiryDate: j['expiryDate'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
