class MaasAvansi {
  final String id;
  final String personelId;
  final DateTime tarih;
  final double tutar;
  final String? aciklama;
  final bool iptal;
  final String? createdBy;
  final DateTime createdAt;

  // Joined alanlar
  final String? personelAdi;

  MaasAvansi({
    required this.id,
    required this.personelId,
    required this.tarih,
    required this.tutar,
    this.aciklama,
    this.iptal = false,
    this.createdBy,
    required this.createdAt,
    this.personelAdi,
  });

  factory MaasAvansi.fromJson(Map<String, dynamic> json) {
    final persData = json['personel'];
    final pAdi = persData is Map<String, dynamic> ? persData['ad_soyad'] as String? : json['personel_adi'] as String?;

    return MaasAvansi(
      id: json['id'] as String,
      personelId: json['personel_id'] as String,
      tarih: DateTime.parse(json['tarih'] as String),
      tutar: (json['tutar'] as num).toDouble(),
      aciklama: json['aciklama'] as String?,
      iptal: json['iptal'] as bool? ?? false,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      personelAdi: pAdi,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personel_id': personelId,
      'tarih': tarih.toIso8601String().split('T')[0],
      'tutar': tutar,
      'aciklama': aciklama,
      'iptal': iptal,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MaasAvansi copyWith({
    String? id,
    String? personelId,
    DateTime? tarih,
    double? tutar,
    String? aciklama,
    bool? iptal,
    String? createdBy,
    DateTime? createdAt,
    String? personelAdi,
  }) {
    return MaasAvansi(
      id: id ?? this.id,
      personelId: personelId ?? this.personelId,
      tarih: tarih ?? this.tarih,
      tutar: tutar ?? this.tutar,
      aciklama: aciklama ?? this.aciklama,
      iptal: iptal ?? this.iptal,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      personelAdi: personelAdi ?? this.personelAdi,
    );
  }

  @override
  String toString() => 'MaasAvansi(id: $id, tutar: $tutar, tarih: $tarih)';
}
