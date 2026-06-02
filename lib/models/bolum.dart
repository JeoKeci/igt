class Bolum {
  final String id;
  final String ad;
  final bool aktif;
  final bool iptal;
  final DateTime createdAt;

  Bolum({
    required this.id,
    required this.ad,
    this.aktif = true,
    this.iptal = false,
    required this.createdAt,
  });

  factory Bolum.fromJson(Map<String, dynamic> json) {
    return Bolum(
      id: json['id'] as String,
      ad: json['ad'] as String,
      aktif: json['aktif'] as bool? ?? true,
      iptal: json['iptal'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ad': ad,
      'aktif': aktif,
      'iptal': iptal,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Bolum copyWith({
    String? id,
    String? ad,
    bool? aktif,
    bool? iptal,
    DateTime? createdAt,
  }) {
    return Bolum(
      id: id ?? this.id,
      ad: ad ?? this.ad,
      aktif: aktif ?? this.aktif,
      iptal: iptal ?? this.iptal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Bolum(id: $id, ad: $ad)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bolum && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
