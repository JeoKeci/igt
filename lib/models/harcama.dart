class Harcama {
  final String id;
  final DateTime tarih;
  final String firma;
  final String? fisNo;
  final String? aciklama;
  final String? plakaStok;
  final String kategoriId;
  final String odemeSekliId;
  final String? projeId;
  final String personelId;
  final double fisTutari;
  final double kdv;
  final double matrah;
  final String? belgeUrl;
  final String? createdBy;
  final bool iptal;
  final DateTime createdAt;

  // Joined fields for display (from related tables)
  final String? kategoriAdi;
  final String? odemeSekliAdi;
  final String? projeAdi;
  final String? personelAdi;

  Harcama({
    required this.id,
    required this.tarih,
    required this.firma,
    this.fisNo,
    this.aciklama,
    this.plakaStok,
    required this.kategoriId,
    required this.odemeSekliId,
    this.projeId,
    required this.personelId,
    required this.fisTutari,
    required this.kdv,
    double? matrah,
    this.belgeUrl,
    this.createdBy,
    this.iptal = false,
    required this.createdAt,
    this.kategoriAdi,
    this.odemeSekliAdi,
    this.projeAdi,
    this.personelAdi,
  }) : matrah = matrah ?? (fisTutari - kdv);

  /// Hesaplanan matrah: fiş tutarı - KDV
  double get hesaplananMatrah => fisTutari - kdv;

  factory Harcama.fromJson(Map<String, dynamic> json) {
    // Handle nested joined table format from Supabase select queries
    // e.g. 'kategoriler': {'ad': 'Yakıt'}, 'odeme_sekilleri': {'ad': 'Nakit'}
    String? extractKategoriAdi(Map<String, dynamic> json) {
      final kategoriler = json['kategoriler'];
      if (kategoriler is Map<String, dynamic>) {
        return kategoriler['ad'] as String?;
      }
      return json['kategori_adi'] as String?;
    }

    String? extractOdemeSekliAdi(Map<String, dynamic> json) {
      final odemeSekilleri = json['odeme_sekilleri'];
      if (odemeSekilleri is Map<String, dynamic>) {
        return odemeSekilleri['ad'] as String?;
      }
      return json['odeme_sekli_adi'] as String?;
    }

    String? extractProjeAdi(Map<String, dynamic> json) {
      final projeler = json['projeler'];
      if (projeler is Map<String, dynamic>) {
        return projeler['ad'] as String?;
      }
      return json['proje_adi'] as String?;
    }

    String? extractPersonelAdi(Map<String, dynamic> json) {
      final personel = json['personel'];
      if (personel is Map<String, dynamic>) {
        return personel['ad_soyad'] as String?;
      }
      return json['personel_adi'] as String?;
    }

    return Harcama(
      id: json['id'] as String,
      tarih: DateTime.parse(json['tarih'] as String),
      firma: json['firma'] as String,
      fisNo: json['fis_no'] as String?,
      aciklama: json['aciklama'] as String?,
      plakaStok: json['plaka_stok'] as String?,
      kategoriId: json['kategori_id'] as String,
      odemeSekliId: json['odeme_sekli_id'] as String,
      projeId: json['proje_id'] as String?,
      personelId: json['personel_id'] as String,
      fisTutari: (json['fis_tutari'] as num).toDouble(),
      kdv: (json['kdv'] as num).toDouble(),
      matrah: json['matrah'] != null
          ? (json['matrah'] as num).toDouble()
          : null,
      belgeUrl: json['belge_url'] as String?,
      createdBy: json['created_by'] as String?,
      iptal: json['iptal'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      kategoriAdi: extractKategoriAdi(json),
      odemeSekliAdi: extractOdemeSekliAdi(json),
      projeAdi: extractProjeAdi(json),
      personelAdi: extractPersonelAdi(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tarih': tarih.toIso8601String().split('T').first,
      'firma': firma,
      'fis_no': fisNo,
      'aciklama': aciklama,
      'plaka_stok': plakaStok,
      'kategori_id': kategoriId,
      'odeme_sekli_id': odemeSekliId,
      'proje_id': projeId,
      'personel_id': personelId,
      'fis_tutari': fisTutari,
      'kdv': kdv,
      'matrah': matrah,
      'belge_url': belgeUrl,
      'created_by': createdBy,
      'iptal': iptal,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Insert/update için sadece veri alanlarını döndürür (id ve created_at hariç)
  Map<String, dynamic> toInsertJson() {
    return {
      'tarih': tarih.toIso8601String().split('T').first,
      'firma': firma,
      'fis_no': fisNo,
      'aciklama': aciklama,
      'plaka_stok': plakaStok,
      'kategori_id': kategoriId,
      'odeme_sekli_id': odemeSekliId,
      'proje_id': projeId,
      'personel_id': personelId,
      'fis_tutari': fisTutari,
      'kdv': kdv,
      'matrah': matrah,
      'belge_url': belgeUrl,
      'created_by': createdBy,
      'iptal': iptal,
    };
  }

  Harcama copyWith({
    String? id,
    DateTime? tarih,
    String? firma,
    String? fisNo,
    String? aciklama,
    String? plakaStok,
    String? kategoriId,
    String? odemeSekliId,
    String? projeId,
    String? personelId,
    double? fisTutari,
    double? kdv,
    double? matrah,
    String? belgeUrl,
    String? createdBy,
    bool? iptal,
    DateTime? createdAt,
    String? kategoriAdi,
    String? odemeSekliAdi,
    String? projeAdi,
    String? personelAdi,
  }) {
    return Harcama(
      id: id ?? this.id,
      tarih: tarih ?? this.tarih,
      firma: firma ?? this.firma,
      fisNo: fisNo ?? this.fisNo,
      aciklama: aciklama ?? this.aciklama,
      plakaStok: plakaStok ?? this.plakaStok,
      kategoriId: kategoriId ?? this.kategoriId,
      odemeSekliId: odemeSekliId ?? this.odemeSekliId,
      projeId: projeId ?? this.projeId,
      personelId: personelId ?? this.personelId,
      fisTutari: fisTutari ?? this.fisTutari,
      kdv: kdv ?? this.kdv,
      matrah: matrah ?? this.matrah,
      belgeUrl: belgeUrl ?? this.belgeUrl,
      createdBy: createdBy ?? this.createdBy,
      iptal: iptal ?? this.iptal,
      createdAt: createdAt ?? this.createdAt,
      kategoriAdi: kategoriAdi ?? this.kategoriAdi,
      odemeSekliAdi: odemeSekliAdi ?? this.odemeSekliAdi,
      projeAdi: projeAdi ?? this.projeAdi,
      personelAdi: personelAdi ?? this.personelAdi,
    );
  }

  @override
  String toString() =>
      'Harcama(id: $id, firma: $firma, fisTutari: $fisTutari, tarih: $tarih)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Harcama && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
