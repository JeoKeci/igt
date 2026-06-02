class Personel {
  final String id;
  final String adSoyad;
  final String eposta;
  final String rol;
  final bool aktif;
  final String? authUserId;
  final bool iptal;
  final DateTime createdAt;

  // Yeni Özlük ve Maaş Alanları
  final String? telefon;
  final String? gorevUnvan;
  final String? kanGrubu;
  final String? acilDurumKisi;
  final String? acilDurumTelefon;
  final String? bolumId;
  final DateTime? iseGirisTarihi;
  final DateTime? istenCikisTarihi;
  final double guncelMaas;
  final String? iban;
  
  // Joined alanlar
  final String? bolumAdi;

  Personel({
    required this.id,
    required this.adSoyad,
    required this.eposta,
    required this.rol,
    this.aktif = true,
    this.authUserId,
    this.iptal = false,
    required this.createdAt,
    this.telefon,
    this.gorevUnvan,
    this.kanGrubu,
    this.acilDurumKisi,
    this.acilDurumTelefon,
    this.bolumId,
    this.iseGirisTarihi,
    this.istenCikisTarihi,
    this.guncelMaas = 0.0,
    this.iban,
    this.bolumAdi,
  });

  /// Yönetici veya muhasebe rolü kontrolü
  bool get isYonetici => rol == 'yonetici' || rol == 'muhasebe';

  /// Saha personeli kontrolü
  bool get isSaha => rol == 'saha';

  factory Personel.fromJson(Map<String, dynamic> json) {
    final bolumData = json['bolumler'];
    final bAdi = bolumData is Map<String, dynamic> ? bolumData['ad'] as String? : json['bolum_adi'] as String?;

    return Personel(
      id: json['id'] as String,
      adSoyad: json['ad_soyad'] as String,
      eposta: json['eposta'] as String,
      rol: json['rol'] as String,
      aktif: json['aktif'] as bool? ?? true,
      authUserId: json['auth_user_id'] as String?,
      iptal: json['iptal'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      telefon: json['telefon'] as String?,
      gorevUnvan: json['gorev_unvan'] as String?,
      kanGrubu: json['kan_grubu'] as String?,
      acilDurumKisi: json['acil_durum_kisi'] as String?,
      acilDurumTelefon: json['acil_durum_telefon'] as String?,
      bolumId: json['bolum_id'] as String?,
      iseGirisTarihi: json['ise_giris_tarihi'] != null ? DateTime.tryParse(json['ise_giris_tarihi'] as String) : null,
      istenCikisTarihi: json['isten_cikis_tarihi'] != null ? DateTime.tryParse(json['isten_cikis_tarihi'] as String) : null,
      guncelMaas: (json['guncel_maas'] as num? ?? 0.0).toDouble(),
      iban: json['iban'] as String?,
      bolumAdi: bAdi,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ad_soyad': adSoyad,
      'eposta': eposta,
      'rol': rol,
      'aktif': aktif,
      'auth_user_id': authUserId,
      'iptal': iptal,
      'created_at': createdAt.toIso8601String(),
      'telefon': telefon,
      'gorev_unvan': gorevUnvan,
      'kan_grubu': kanGrubu,
      'acil_durum_kisi': acilDurumKisi,
      'acil_durum_telefon': acilDurumTelefon,
      'bolum_id': bolumId,
      'ise_giris_tarihi': iseGirisTarihi?.toIso8601String().split('T')[0],
      'isten_cikis_tarihi': istenCikisTarihi?.toIso8601String().split('T')[0],
      'guncel_maas': guncelMaas,
      'iban': iban,
    };
  }

  Personel copyWith({
    String? id,
    String? adSoyad,
    String? eposta,
    String? rol,
    bool? aktif,
    String? authUserId,
    bool? iptal,
    DateTime? createdAt,
    String? telefon,
    String? gorevUnvan,
    String? kanGrubu,
    String? acilDurumKisi,
    String? acilDurumTelefon,
    String? bolumId,
    DateTime? iseGirisTarihi,
    DateTime? istenCikisTarihi,
    double? guncelMaas,
    String? iban,
    String? bolumAdi,
  }) {
    return Personel(
      id: id ?? this.id,
      adSoyad: adSoyad ?? this.adSoyad,
      eposta: eposta ?? this.eposta,
      rol: rol ?? this.rol,
      aktif: aktif ?? this.aktif,
      authUserId: authUserId ?? this.authUserId,
      iptal: iptal ?? this.iptal,
      createdAt: createdAt ?? this.createdAt,
      telefon: telefon ?? this.telefon,
      gorevUnvan: gorevUnvan ?? this.gorevUnvan,
      kanGrubu: kanGrubu ?? this.kanGrubu,
      acilDurumKisi: acilDurumKisi ?? this.acilDurumKisi,
      acilDurumTelefon: acilDurumTelefon ?? this.acilDurumTelefon,
      bolumId: bolumId ?? this.bolumId,
      iseGirisTarihi: iseGirisTarihi ?? this.iseGirisTarihi,
      istenCikisTarihi: istenCikisTarihi ?? this.istenCikisTarihi,
      guncelMaas: guncelMaas ?? this.guncelMaas,
      iban: iban ?? this.iban,
      bolumAdi: bolumAdi ?? this.bolumAdi,
    );
  }

  @override
  String toString() => 'Personel(id: $id, adSoyad: $adSoyad, rol: $rol)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Personel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
