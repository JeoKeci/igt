class Proje {
  final String id;
  final String ad;
  final String? bolumId;
  final String? lokasyon;
  final DateTime? baslangicTarihi;
  final DateTime? bitisTarihi;
  final String durum;
  final bool aktif;
  final bool iptal;
  final DateTime createdAt;

  Proje({
    required this.id,
    required this.ad,
    this.bolumId,
    this.lokasyon,
    this.baslangicTarihi,
    this.bitisTarihi,
    this.durum = 'aktif',
    this.aktif = true,
    this.iptal = false,
    required this.createdAt,
  });

  factory Proje.fromJson(Map<String, dynamic> json) {
    return Proje(
      id: json['id'] as String,
      ad: json['ad'] as String,
      bolumId: json['bolum_id'] as String?,
      lokasyon: json['lokasyon'] as String?,
      baslangicTarihi: json['baslangic_tarihi'] != null
          ? DateTime.parse(json['baslangic_tarihi'] as String)
          : null,
      bitisTarihi: json['bitis_tarihi'] != null
          ? DateTime.parse(json['bitis_tarihi'] as String)
          : null,
      durum: json['durum'] as String? ?? 'aktif',
      aktif: json['aktif'] as bool? ?? true,
      iptal: json['iptal'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ad': ad,
      'bolum_id': bolumId,
      'lokasyon': lokasyon,
      'baslangic_tarihi': baslangicTarihi?.toIso8601String(),
      'bitis_tarihi': bitisTarihi?.toIso8601String(),
      'durum': durum,
      'aktif': aktif,
      'iptal': iptal,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Proje copyWith({
    String? id,
    String? ad,
    String? bolumId,
    String? lokasyon,
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
    String? durum,
    bool? aktif,
    bool? iptal,
    DateTime? createdAt,
  }) {
    return Proje(
      id: id ?? this.id,
      ad: ad ?? this.ad,
      bolumId: bolumId ?? this.bolumId,
      lokasyon: lokasyon ?? this.lokasyon,
      baslangicTarihi: baslangicTarihi ?? this.baslangicTarihi,
      bitisTarihi: bitisTarihi ?? this.bitisTarihi,
      durum: durum ?? this.durum,
      aktif: aktif ?? this.aktif,
      iptal: iptal ?? this.iptal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Proje(id: $id, ad: $ad, durum: $durum)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Proje && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
