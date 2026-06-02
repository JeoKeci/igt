class IsAvansi {
  final String id;
  final DateTime tarih;
  final String personelId;
  final double tutar;
  final String tur; // 'avans_verildi', 'onceki_aydan_devir'
  final String? aciklama;
  final bool iptal;
  final DateTime createdAt;

  // Joined alanlar
  final String? personelAdi;

  IsAvansi({
    required this.id,
    required this.tarih,
    required this.personelId,
    required this.tutar,
    required this.tur,
    this.aciklama,
    this.iptal = false,
    required this.createdAt,
    this.personelAdi,
  });

  factory IsAvansi.fromJson(Map<String, dynamic> json) {
    final persData = json['personel'];
    final pAdi = persData is Map<String, dynamic> ? persData['ad_soyad'] as String? : json['personel_adi'] as String?;

    return IsAvansi(
      id: json['id'] as String,
      tarih: DateTime.parse(json['tarih'] as String),
      personelId: json['personel_id'] as String,
      tutar: (json['tutar'] as num).toDouble(),
      tur: json['tur'] as String,
      aciklama: json['aciklama'] as String?,
      iptal: json['iptal'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      personelAdi: pAdi,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tarih': tarih.toIso8601String().split('T')[0],
      'personel_id': personelId,
      'tutar': tutar,
      'tur': tur,
      'aciklama': aciklama,
      'iptal': iptal,
      'created_at': createdAt.toIso8601String(),
    };
  }

  IsAvansi copyWith({
    String? id,
    DateTime? tarih,
    String? personelId,
    double? tutar,
    String? tur,
    String? aciklama,
    bool? iptal,
    DateTime? createdAt,
    String? personelAdi,
  }) {
    return IsAvansi(
      id: id ?? this.id,
      tarih: tarih ?? this.tarih,
      personelId: personelId ?? this.personelId,
      tutar: tutar ?? this.tutar,
      tur: tur ?? this.tur,
      aciklama: aciklama ?? this.aciklama,
      iptal: iptal ?? this.iptal,
      createdAt: createdAt ?? this.createdAt,
      personelAdi: personelAdi ?? this.personelAdi,
    );
  }

  @override
  String toString() => 'IsAvansi(id: $id, tutar: $tutar, tarih: $tarih)';
}
