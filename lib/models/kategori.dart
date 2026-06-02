class Kategori {
  final String id;
  final int no;
  final String ad;
  final String? bolumId;
  final bool aktif;
  final bool iptal;
  final DateTime createdAt;

  Kategori({
    required this.id,
    required this.no,
    required this.ad,
    this.bolumId,
    this.aktif = true,
    this.iptal = false,
    required this.createdAt,
  });

  factory Kategori.fromJson(Map<String, dynamic> json) {
    return Kategori(
      id: json['id'] as String,
      no: json['no'] as int,
      ad: json['ad'] as String,
      bolumId: json['bolum_id'] as String?,
      aktif: json['aktif'] as bool? ?? true,
      iptal: json['iptal'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'no': no,
      'ad': ad,
      'bolum_id': bolumId,
      'aktif': aktif,
      'iptal': iptal,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Kategori copyWith({
    String? id,
    int? no,
    String? ad,
    String? bolumId,
    bool? aktif,
    bool? iptal,
    DateTime? createdAt,
  }) {
    return Kategori(
      id: id ?? this.id,
      no: no ?? this.no,
      ad: ad ?? this.ad,
      bolumId: bolumId ?? this.bolumId,
      aktif: aktif ?? this.aktif,
      iptal: iptal ?? this.iptal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Kategori(id: $id, no: $no, ad: $ad)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Kategori && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
