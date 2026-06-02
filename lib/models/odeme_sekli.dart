class OdemeSekli {
  final String id;
  final String kod;
  final String ad;
  final bool iptal;
  final DateTime createdAt;

  OdemeSekli({
    required this.id,
    required this.kod,
    required this.ad,
    this.iptal = false,
    required this.createdAt,
  });

  factory OdemeSekli.fromJson(Map<String, dynamic> json) {
    return OdemeSekli(
      id: json['id'] as String,
      kod: json['kod'] as String,
      ad: json['ad'] as String,
      iptal: json['iptal'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kod': kod,
      'ad': ad,
      'iptal': iptal,
      'created_at': createdAt.toIso8601String(),
    };
  }

  OdemeSekli copyWith({
    String? id,
    String? kod,
    String? ad,
    bool? iptal,
    DateTime? createdAt,
  }) {
    return OdemeSekli(
      id: id ?? this.id,
      kod: kod ?? this.kod,
      ad: ad ?? this.ad,
      iptal: iptal ?? this.iptal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'OdemeSekli(id: $id, kod: $kod, ad: $ad)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OdemeSekli &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
